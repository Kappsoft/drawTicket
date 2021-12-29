// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */
 
contract DrawTicket is VRFConsumerBase, Ownable {
    
    bytes32 internal keyHash;
    bytes32 public winnerKeyHash;
    bytes32 public firstRunnerupkeyHash;
    bytes32 public secondRunnerupKeyHash;
    uint256 internal fee;
    uint256[] public tickets;
    uint256 public winner;
    uint256 public firstRunnerup;
    uint256 public secondRunnerup;
    uint256 public randomNumber;
    bytes32 private _requestId;
    bytes32 public drawKey;

    event randomnessFullfilled(uint256 random);
    event winnerSelected(uint256 winningPosition, uint256 winnerId);
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Polygon Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     * winnerKeyHash = 0x474ec189d0751eef3d42fe7b893533ef710266c762661f61234903abc1cdde1d;
     * firstRunnerupkeyHash = 0x8eb86ccc5556f12b673c062b79490eb5025bc3cbc8db4a9571f3e2c9d3672415;
     * secondRunnerupKeyHash = 0x03dc587b4bab8c8bf4769af29b8b79e3964f6fbc372ca9fb31aa3028894b9fd3;
     */
    constructor(address _VRFCoordinator, address _LINKToken, bytes32 _keyHash, bytes32 _winnerKeyHash, bytes32 _firstRunnerupkeyHash, bytes32 _secondRunnerupKeyHash) 
        VRFConsumerBase(
            _VRFCoordinator, // VRF Coordinator
            _LINKToken  // LINK Token
        )
    {
        keyHash = _keyHash;
        winnerKeyHash = _winnerKeyHash;
        firstRunnerupkeyHash = _firstRunnerupkeyHash;
        secondRunnerupKeyHash = _secondRunnerupKeyHash;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (for Polygon chain)
    }

    function uploadTickets(uint256[] calldata ticketData) public onlyOwner {
        for (uint256 i; i<ticketData.length; i++){
            tickets.push(ticketData[i]);
        }
    }
    
    /** 
     * Requests randomness 
     */
    function pickWinner(string memory key) public {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        _requestId = requestRandomness(keyHash, fee);
        drawKey = keccak256(abi.encodePacked(key));
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(requestId == _requestId);
        _pickWinner(randomness);
        emit randomnessFullfilled(randomness);
    }

    function _pickWinner(uint256 randomness) internal virtual {
        randomNumber = randomness;
        uint256 winnerSlot = randomness % tickets.length;
        if(drawKey == winnerKeyHash){
            require(winner == 0, "already picked winner");
            winner = tickets[winnerSlot];
            emit winnerSelected(winnerSlot, winner);
        }
        else if(drawKey == firstRunnerupkeyHash){
            require(firstRunnerup == 0, "already picked first runner up");
            firstRunnerup = tickets[winnerSlot];
            emit winnerSelected(winnerSlot, firstRunnerup);
        }
        else if(drawKey == secondRunnerupKeyHash){
            require(secondRunnerup == 0, "already picked second runner up");
            secondRunnerup = tickets[winnerSlot];
            emit winnerSelected(winnerSlot, secondRunnerup);
        }
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}
