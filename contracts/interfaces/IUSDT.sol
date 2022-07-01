// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUSDT {
    function transfer(address _to, uint256 _value) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;
}
