pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;
  bool public openForWithdraw = false;
  
  event Staked(address staker, uint256 amount);
  event Withdrawal(address receiver, uint256 amount);
  event Executed(uint256 contractBalance, uint256 deadline);

  modifier afterDeadline() {
    require(block.timestamp > deadline,'Deadline has not passed yet.');
    _;
  }
  modifier beforeDeadline() {
    require(block.timestamp <= deadline,'Deadline has passed');
    _;
  }
  modifier openWithdraw() {
    require(openForWithdraw == true, 'Staking pool is not currently open for withdrawal.');
    _;
  }

  function stake(uint256 _amount) public payable beforeDeadline(){
    balances[msg.sender] += _amount;

    emit Staked(msg.sender, _amount);
  }

  function withdraw(uint256 _amount ) public openWithdraw() {
    require (_amount <= balances[msg.sender], 'Balance does not cover withdrawal request.');
      balances[msg.sender] -= _amount;
      payable(msg.sender).transfer(_amount);

      emit Withdrawal(msg.sender, _amount);
  }

  function timeLeft() public view returns(uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return (deadline - block.timestamp);
    }
  }

  function getBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function execute() public {
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      deadline = block.timestamp + 30 seconds;
      openForWithdraw = false;
    } else if (address(this).balance < threshold) {
      openForWithdraw = true;
    }
    emit Executed(address(this).balance,deadline);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  // Add the `receive()` special function that receives eth and calls stake()
}
