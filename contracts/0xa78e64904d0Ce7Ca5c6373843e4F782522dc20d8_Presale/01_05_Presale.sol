// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Presale is Ownable {
    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;
    uint256 public presaleHardcap;
    uint256 public tokensPerEth;
    uint256 public minimumContribution;
    uint256 public maximumContribution;
    uint256 public currentlyRaised;
    uint256 public totalContributors;

    uint8 internal constant DECIMAL_PLACES = 18;
    uint256 internal constant RATE_SCALE = 10**DECIMAL_PLACES;

    IERC20 public token;

    bool public isPresaleActive = true;
    bool public publicPresale = false;
    bool public isWithdrawingAllowed = false;

    mapping(address => uint256) public contributions;
    mapping(address => uint256) public tokenBalances;

    bytes32 public merkleRoot =
        0xbba1b61f9e829d97df1f669d14b32b2e4abba8d81a44a991de499eea96bf1408;

    event TokensPurchased(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    event TokensClaimed(address indexed buyer, uint256 tokenAmount);

    /**
     * @dev Constructor
     */
    constructor(
        address _tokenAddress,
        uint256 _presaleStartTimestamp,
        uint256 _presaleEndTimestamp,
        uint256 _presaleHardcap,
        uint256 _tokensPerEth,
        uint256 _minimumContribution,
        uint256 _maximumContribution,
        bytes32 _merkleRoot,
        bool _publicPresale
    ) {
        token = IERC20(_tokenAddress);
        presaleStartTimestamp = _presaleStartTimestamp;
        presaleEndTimestamp = _presaleEndTimestamp;
        presaleHardcap = _presaleHardcap;
        tokensPerEth = _tokensPerEth;
        minimumContribution = _minimumContribution;
        maximumContribution = _maximumContribution;
        merkleRoot = _merkleRoot;
        publicPresale = _publicPresale;
    }

    /**
     * @dev Change contract settings
     * @param _presaleStartTimestamp Presale start timestamp [Unix]
     * @param _presaleEndTimestamp Presale end timestamp [Unix]
     * @param _presaleHardcap Presale hardcap  [Wei]
     * @param _tokensPerEth ETH per token unit [Wei]
     * @param _minimumContribution Minimum ETH per wallet [Wei]
     * @param _maximumContribution Maximum ETH per wallet  [Wei]
     */
    function changeContractSettings(
        uint256 _presaleStartTimestamp,
        uint256 _presaleEndTimestamp,
        uint256 _presaleHardcap,
        uint256 _tokensPerEth,
        uint256 _minimumContribution,
        uint256 _maximumContribution
    ) public onlyOwner {
        presaleStartTimestamp = _presaleStartTimestamp;
        presaleEndTimestamp = _presaleEndTimestamp;
        presaleHardcap = _presaleHardcap;
        tokensPerEth = _tokensPerEth;
        minimumContribution = _minimumContribution;
        maximumContribution = _maximumContribution;
    }

    /**
     * @dev Change merkle root
     * @param _merkleRoot Merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setIsWithdrawingAllowed(bool _isWithdrawingAllowed)
        public
        onlyOwner
    {
        isWithdrawingAllowed = _isWithdrawingAllowed;
    }

    function verifyMerkleProof(bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @dev Change presale status
     * @param _isPresaleActive Presale status [true/false]
     */
    function changePresaleStatus(bool _isPresaleActive) public onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    function buyTokens(bytes32[] calldata _merkleProof) external payable {
        require(isPresaleActive, "Presale is paused");

        if (publicPresale == false) {
            require(verifyMerkleProof(_merkleProof), "Merkle proof is not valid");
        }

        require(
            block.timestamp >= presaleStartTimestamp,
            "Presale has not started yet"
        );

        require(
            block.timestamp <= presaleEndTimestamp,
            "Presale has already ended"
        );

        require(
            msg.value >= minimumContribution,
            "Minimum contribution is not met"
        );

        // Increase the contributors count

        if (contributions[msg.sender] == 0) {
            totalContributors++;
        }

        uint256 contribution = contributions[msg.sender] + msg.value;

        require(
            contribution <= maximumContribution,
            "Maximum contribution is exceeded"
        );

        contributions[msg.sender] = contribution;

        // Calculate tokens to mint
        uint256 tokensToMint = (msg.value * tokensPerEth) / RATE_SCALE;

        require(
            token.balanceOf(address(this)) >= tokensToMint,
            "Not enough tokens left for sale"
        );

        tokenBalances[msg.sender] += tokensToMint;

        currentlyRaised += msg.value;

        if (address(this).balance >= presaleHardcap) {
            isPresaleActive = false;
        }

        emit TokensPurchased(msg.sender, msg.value, tokensToMint);
    }

    /**
     * @dev Withdraw ETH from the contract to the sender's wallet.
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawErc() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * Claim the tokens bought in the presale
     */
    function claimTokens() public {
        require(tokenBalances[msg.sender] > 0, "No tokens to claim");

        if (block.timestamp < presaleEndTimestamp) {
            require(isPresaleActive == false, "Presale is still active");

            require(
                currentlyRaised >= presaleHardcap,
                "Presale is not finished yet"
            );
        }

        require(isWithdrawingAllowed, "Withdrawals are not allowed yet");

        uint256 tokensToClaim = tokenBalances[msg.sender];
        tokenBalances[msg.sender] = 0;

        token.transfer(msg.sender, tokensToClaim);

        emit TokensClaimed(msg.sender, tokensToClaim);
    }
}