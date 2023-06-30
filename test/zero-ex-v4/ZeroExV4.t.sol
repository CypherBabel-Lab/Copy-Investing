// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/external-interfaces/IZeroExV4.sol";

contract ZeroExV4Test is Test {
    
    function test_encodeZeroExRfqOrderArgs() public
    {
        IZeroExV4.RfqOrder memory order = IZeroExV4.RfqOrder({
            makerToken: address(0xE03489D4E90b22c59c5e23d45DFd59Fc0dB8a025),
            takerToken: address(0xd393b1E02dA9831Ff419e22eA105aAe4c47E1253),
            makerAmount: 100000000000000000000,
            takerAmount: 100000000000000000000,
            maker: address(0x2c313d9c2D84E793285A576630f38F38331718D0),
            taker: address(0x000),
            txOrigin: address(0),
            pool: bytes32(0),
            expiry: 13124141,
            salt: 1992931
        });
        IZeroExV4.Signature memory signature = IZeroExV4.Signature({
            signatureType: IZeroExV4.SignatureType.EIP712,
            v: 28,
            r: bytes32(0x44088c6e7926a1cc6ff8bded20c11d100682f1284c548c9220bc01363def1d10),
            s: bytes32(0x60e186d9a84c0944ce32d3bd17f0eadf8d92ee12a7e32f170fc7ea2bc511900e)
        });
        bytes memory result = abi.encode(order, signature);
        emit log_named_bytes("result", result);
    }
}