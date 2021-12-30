// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DrawTicket is VRFConsumerBase, Ownable {
    bytes32 private _requestId;

    /**
     *@dev
     *Refference:https://docs.chain.link/docs/vrf-contracts/
     * fee = 0.0001 LINK (for Polygon chain)
     */
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal randomNumber;
    bytes32 public winnerKeyHash;
    bytes32 public firstRunnerupkeyHash;
    bytes32 public secondRunnerupKeyHash;
    bytes32 public drawKey;
    uint256 public winner;
    uint256 public firstRunnerup;
    uint256 public secondRunnerup;

    /**
     *@dev stores all issued ticket Id
     */
    uint256[] public tickets;
    event winnerSelected(uint256 winningPosition, uint256 winnerId);

    /**
     * @notice
     *
     * Network: Polygon(Matic) Mainnet
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash: 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     *
     * Network: Polygon(Matic) Mumbai Testnet
     * Chainlink VRF Coordinator address: 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
     * LINK token address:                0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Key Hash: 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
     *
     * Reference: https://docs.chain.link/docs/vrf-contracts/
     *
     * @notice The values given below are for testing.
     * winnerKeyHash:  0x474ec189d0751eef3d42fe7b893533ef710266c762661f61234903abc1cdde1d;
     * @dev the above hash is generated with keccak256(abi.encodePacked(winnerKeyHash));
     * firstRunnerupkeyHash: 0x8eb86ccc5556f12b673c062b79490eb5025bc3cbc8db4a9571f3e2c9d3672415;
     * @dev the above hash is generated with keccak256(abi.encodePacked(firstRunnerupkeyHash));
     * secondRunnerupKeyHash: 0x03dc587b4bab8c8bf4769af29b8b79e3964f6fbc372ca9fb31aa3028894b9fd3;
     * @dev the above hash is generated with keccak256(abi.encodePacked(secondRunnerupKeyHash));
     */

    /** @dev  Constructor inherits VRFConsumerBase.
     */
    constructor(
        address _VRFCoordinator,
        address _LINKToken,
        bytes32 _keyHash,
        bytes32 _winnerKeyHash,
        bytes32 _firstRunnerupkeyHash,
        bytes32 _secondRunnerupKeyHash
    ) VRFConsumerBase(_VRFCoordinator, _LINKToken) {
        keyHash = _keyHash; //key hash to fetch randomness
        winnerKeyHash = _winnerKeyHash; //hash of key to pick winner
        firstRunnerupkeyHash = _firstRunnerupkeyHash; //hash of key to pick first runnerup
        secondRunnerupKeyHash = _secondRunnerupKeyHash; //hash of key to pick second runnerup
        fee = 0.0001 * 10**18; // 0.0001 LINK (for Polygon chain)
    }

    /**
     *@dev function to withdraw all LINK to avoid locking your LINK in the contract.
     *@param _LINKToken address of the locked token.
     *Requirements:
     * - the caller must be the owner of the contract.
     */
    function withdrawLink(address _LINKToken) external onlyOwner {
        IERC20 LINK = IERC20(_LINKToken);
        uint256 amount = LINK.balanceOf(address(this));
        LINK.transfer(owner(), amount);
    }

    /**
     *@dev external function to view all issued tickets.
     *@return array contains ticket Id.
     */
    function getAllTickets() external view returns (uint256[] memory) {
        return tickets;
    }

    /**
     *@dev function to store all issued tickets
     *@param ticketData the array contains issued ticket id
     */
    function uploadTickets(uint256[] calldata ticketData) public onlyOwner {
        for (uint256 i; i < ticketData.length; i++) {
            tickets.push(ticketData[i]);
        }
    }

    /**
     *@dev Requests  randomness to pick a winner.
     * also store a key to choose winner position
     *@param key the word used for creating key
     */
    function pickWinner(string memory key) public {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        _requestId = requestRandomness(keyHash, fee);
        drawKey = keccak256(abi.encodePacked(key));
    }

    /**
     *@dev internal callback function used by VRF Coordinator.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(requestId == _requestId);
        _pickWinner(randomness);
    }

    /**
     *@dev internal function with random winner selection logic.
     *@param randomness random number provided by VRF Coordinator.
     */
    function _pickWinner(uint256 randomness) internal virtual {
        randomNumber = randomness;
        uint256 winnerSlot = randomness % tickets.length;
        if (drawKey == winnerKeyHash) {
            require(winner == 0, "already picked winner");
            winner = tickets[winnerSlot];
            emit winnerSelected(winnerSlot, winner);
        } else if (drawKey == firstRunnerupkeyHash) {
            require(firstRunnerup == 0, "already picked first runner up");
            firstRunnerup = tickets[winnerSlot];
            emit winnerSelected(winnerSlot, firstRunnerup);
        } else if (drawKey == secondRunnerupKeyHash) {
            require(secondRunnerup == 0, "already picked second runner up");
            secondRunnerup = tickets[winnerSlot];
            emit winnerSelected(winnerSlot, secondRunnerup);
        }
    }
}
