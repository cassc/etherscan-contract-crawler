// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IFair721NFT {
    function amountOf(uint256 tokenId) external view returns (uint256);

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Fair721TokenUpgrade is ERC20, Ownable {
    IFair721NFT public constant FAIR721NFT = IFair721NFT(0xE7667Cb1cd8FE89AA38d7F20DCC50ee262cC9D12);

    address public constant DEV_ADDRESS = address(0xAC10B81b9A1D4113feF21f889Dc91d66889D961f);
    address public constant LP_ADD_ADDRESS = address(0xc14C6F1B41B5159b83C626eBd8f4b00FaEd8E921);

    uint256 public BURN_FEE = 0.002 ether;

    uint256 public START_TIME = 0xffffffff;
    uint256 public CONVERT_END = 0xfffffffff;
    address public CREATOR;

    uint256 public constant USER_RATE = 500;
    uint256 public constant LP_RATE = 490;

    uint256 public constant CLAIM_SUPPLY = 28_328_070_000 * 1e18;

    constructor() ERC20("Fair 721 Token Upgrade", "F721U") {
        CREATOR = msg.sender;
        _mint(address(this), CLAIM_SUPPLY);
        _transfer(address(this), msg.sender, 8_000_000_000 * 1e18);
    }

    function burnUnclaimed(uint256 amount) external onlyOwner {
        require(block.timestamp > CLAIMED_END, "not end");
        _transfer(address(this), address(57005), amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        require(block.timestamp > START_TIME || from == address(this) || to == address(this) || from == owner() || to == owner(), "not start");
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        START_TIME = _startTime;
        CONVERT_END = START_TIME + 30 * 3600;
        CLAIMED_END = START_TIME + 3 * 24 * 3600;
    }

    function batchConvert(uint256[] memory tokenIds) external payable {
        require(msg.sender == tx.origin, "EOA");
        require(block.timestamp >= START_TIME || msg.sender == owner(), "not start");
        require(block.timestamp < CONVERT_END, "end");

        uint256 count = tokenIds.length;
        require(msg.value >= BURN_FEE * count, "fee");
        uint256 totalMintAmount = 0;
        for (uint256 i = 0; i < count; i++) {
            require(FAIR721NFT.ownerOf(tokenIds[i]) == msg.sender, "owner");
            uint256 tokenAmount = FAIR721NFT.amountOf(tokenIds[i]);
            FAIR721NFT.burn(tokenIds[i]);
            totalMintAmount += tokenAmount * 10000 * 1e18;
        }

        _mint(address(this), totalMintAmount);

        uint256 userAmount = totalMintAmount / 1000 * USER_RATE;
        uint256 lpAmount = totalMintAmount / 1000 * LP_RATE;
        uint256 devAmount = totalMintAmount - userAmount - lpAmount;

        _transfer(address(this), msg.sender, userAmount);
        _transfer(address(this), LP_ADD_ADDRESS, lpAmount);
        _transfer(address(this), DEV_ADDRESS, devAmount);
        (bool s,) = LP_ADD_ADDRESS.call{value: msg.value}("");
        require(s, "transfer failed");
    }

    mapping(address => bool) public HAS_CLAIMED;
    uint256 public CLAIMED_END = 0xfffffffff;

    function claim(uint256 amount, bytes calldata signature) external {
        require(!HAS_CLAIMED[msg.sender], "claimed");
        require(block.timestamp >= START_TIME || msg.sender == owner(), "not start");
        require(block.timestamp < CLAIMED_END, "end");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, amount));
        require(ECDSA.recover(message, signature) == address(0xfB07a2Dc7C34E1d723f14a5Bb2f116064DcD26df), "invalid signature");
        HAS_CLAIMED[msg.sender] = true;
        _transfer(address(this), msg.sender, amount);
    }
}