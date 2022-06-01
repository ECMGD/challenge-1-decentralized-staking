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
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;
  
  event Staked(address staker, uint256 amount);
  event Withdrawal(address receiver);
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
  
  receive() external payable {
    stake();
}

  function stake() public payable beforeDeadline(){
    balances[msg.sender] += msg.value;

    emit Staked(msg.sender, msg.value);
  }

  function withdraw( ) public openWithdraw() afterDeadline() {
    require (balances[msg.sender] > 0, 'Balance does not cover withdrawal request.');
      balances[msg.sender] = 0;
      (bool sent, bytes memory data) = msg.sender.call{value: balances[msg.sender]}("");
      require(sent, "Failed to send Ether");

      emit Withdrawal(msg.sender);
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

  function execute() public afterDeadline() {
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

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
}
