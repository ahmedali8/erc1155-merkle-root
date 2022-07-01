// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { Test } from "forge-std/Test.sol";

contract Utils is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextUserAddress() public returns (address payable) {
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    // create user with 100 eth balance
    function createUser() public returns (address payable) {
        address payable user = this.getNextUserAddress();
        vm.deal(user, 100 ether);
        return user;
    }

    // create user with `bal` balance
    function createUser(uint256 bal) public returns (address payable) {
        address payable user = this.getNextUserAddress();
        vm.deal(user, bal);
        return user;
    }

    // create users with 100 ETH balance each
    function createUsers(uint256 userNum) public returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            users[i] = this.createUser();
        }

        return users;
    }

    // move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) public returns (uint256) {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
        return targetBlock;
    }

    // to wei converter
    function toWei(uint256 value) public pure returns (uint256) {
        return value * 1e18;
    }

    // to wei converter with custom decimals
    function toWei(uint256 value, uint256 decimals) public pure returns (uint256) {
        uint256 exponentDecimals = 1;
        for (uint256 i = 0; i < decimals; ++i) {
            exponentDecimals *= 10;
        }
        return value * exponentDecimals;
    }
}
