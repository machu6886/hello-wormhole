// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/HelloWormhole.sol";
import "./MockWormholeRelayer.sol";
import "../src/interfaces/IWormholeRelayer.sol";

contract SavingsAccountTest is Test {
    event MessageReceived(string greeting, uint16 senderChain, address sender);
    IWormholeRelayer relayer;
    MockWormholeRelayer _mockRelayer;

    HelloWormhole helloA;
    HelloWormhole helloB;

    uint16 constant targetChain = 4;

    function setUp() public {
        // set up Mock Wormhole Relayer
        _mockRelayer = new MockWormholeRelayer();
        address _relayer = address(_mockRelayer);
        (bool success, ) = _relayer.call{value: 100e18}("");
        require(success);
        relayer = IWormholeRelayer(_relayer);

        // set up HelloWormhole contracts
        helloA = new HelloWormhole(_relayer);
        helloB = new HelloWormhole(_relayer);
    }

    function testNative() public {
        (uint256 cost, ) = relayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            30_000
        );

        helloA.sendGreeting{value: cost}(
            targetChain,
            address(helloB),
            "Hello Wormhole!"
        );

        vm.expectEmit();
        emit MessageReceived(
            "Hello Wormhole!",
            _mockRelayer.chainId(),
            address(helloA)
        );
        _mockRelayer.performRecordedDeliveries();
    }

    receive() external payable {}
}
