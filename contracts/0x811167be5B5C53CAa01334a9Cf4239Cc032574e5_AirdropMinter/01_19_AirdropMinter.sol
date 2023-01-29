// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MIRLERC20.sol";

contract AirdropMinter is Ownable {
    using SafeERC20 for IERC20;
    MadeInRealLife private token; // MIRL ERC20 Token
    address private contractAddress; // MIRL ERC20 Token Address
    address private conditionalTokenAddress; // MIRL NFT token address
    bytes32 private merkleRoot;
    mapping(uint256 => uint256) private startTimes;
    uint256 private numberOfRounds;
    mapping(address => uint256) private latestMintTimes;

    constructor() {}

    receive() external payable {}

    fallback() external payable {}

    /**
  ***************************
  Validate if wallet address is in whitelisted
  ***************************
   */
    function validateAddress(
        bytes32[] calldata merkleProof,
        address walletAddress,
        uint256 amount
    ) public view returns (bool) {
        string memory addressString = Strings.toHexString(
            uint256(uint160(walletAddress)),
            20
        );
        string memory addressWithAmount = string(
            abi.encodePacked(addressString, "-", Strings.toString(amount))
        );
        bytes32 leaf = keccak256(abi.encodePacked(addressWithAmount));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }
    /**
  ***************************
  Validate if wallet address have MIRL NFT
  ***************************
   */
    function validateConditionalTokenAmount(address walletAddress)
        public
        view
        returns (bool)
    {
        IERC20 conditionalToken = IERC20(conditionalTokenAddress);
        uint256 balance = conditionalToken.balanceOf(walletAddress);
        return balance > 0;
    }

    /**
  ***************************
  Validate if wallet address is not airdropped
  ***************************
   */
    function validateAirdropRound(address walletAddress)
        public
        view
        returns (bool, uint256)
    {
        uint256 latestMintTime = latestMintTimes[walletAddress];
        uint256 currentTime = getCurrentBlockTime();
        uint256 activeStartTime;
        uint256 pendingRound;
        for (uint256 i = 0; i < numberOfRounds - 1; i++) {
            if (
                latestMintTime < startTimes[i] && startTimes[i] <= currentTime
            ) {
                pendingRound++;
            }
            if (
                startTimes[i] <= currentTime && currentTime < startTimes[i + 1]
            ) {
                activeStartTime = startTimes[i];
            }
        }

        bool isValid = activeStartTime > latestMintTime;

        return (isValid, pendingRound);
    }

    function canMint(
        address walletAddress,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) public view returns (bool) {
        (bool isValidAirdropRound, ) = validateAirdropRound(walletAddress);
        return
            validateAddress(merkleProof, walletAddress, amount) &&
            validateConditionalTokenAmount(walletAddress) &&
            isValidAirdropRound;
    }

    /**
  ***************************
  Public
  ***************************
   */

    function mint(
        address to,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) public {
        require(
            validateConditionalTokenAmount(to),
            "Address doesn't meet requirement"
        );
        require(
            validateAddress(merkleProof, to, amount),
            "Address is not valid"
        );

        (bool isValidAirdropRound, uint256 pendingRound) = validateAirdropRound(
            to
        );
        require(isValidAirdropRound, "Already claim airdrop this round");

        token.mint(to, pendingRound * amount);
        latestMintTimes[to] = getCurrentBlockTime();
    }

    /**
  ***************************
  Customization for the contract
  ***************************
   */

    function getCurrentBlockTime() public view returns (uint256) {
        return block.timestamp * 1000;
    }

    function getLatestMintTime(address walletAddress)
        public
        view
        returns (uint256)
    {
        return latestMintTimes[walletAddress];
    }

    function setContractAddress(address payable _address) public onlyOwner {
        contractAddress = _address;
        token = MadeInRealLife(_address);
    }

    function getContractAddress() public
        view
        returns (string memory){
        return Strings.toHexString(uint256(uint160(contractAddress)), 20);

    }

    function setConditionalTokenAddress(address _address) public onlyOwner {
        conditionalTokenAddress = _address;
    }

    function getConditionalTokenAddress() public
        view
        returns (string memory){
        return Strings.toHexString(uint256(uint160(conditionalTokenAddress)), 20);

    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setStartTimes(uint256[] calldata defaultStartTimes)
        public
        onlyOwner
    {
        numberOfRounds = defaultStartTimes.length;
        for (uint256 i = 0; i < defaultStartTimes.length; i++) {
            startTimes[i] = defaultStartTimes[i];
        }
    }
}