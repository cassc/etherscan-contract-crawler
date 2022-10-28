// SPDX-License-Identifier: MIT
// 1. Set the staking contract Address
// 2. For each Artifact:
//     - a. Set the total staked HT treshold for the reward
//     - b. Set the token URI
//     - c. Enable the mint when required

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

interface StakingContract {
    function calculateTotalAndPendingRewards(address _user) external view returns(uint);
}

contract Artifacts is ERC1155, ERC1155Burnable, Ownable {
    using ECDSA for bytes32;
    struct TokenInfo {
        uint tokensRequired;
        bool mintEnabled;
        mapping(address => bool) hasClaimedReward;
        string tokenURI;
    }
    constructor(address _initialSigner, address _stakingContract) ERC1155("") {
        _signer = _initialSigner;
        stakingContract = StakingContract(_stakingContract);
    }

    ////////////////////////////////////////////
    /// Contract variables
    ////////////////////////////////////////////
    StakingContract private stakingContract;
    mapping(uint => TokenInfo) public tokenInfo;
    address private _signer;
    
    ////////////////////////////////////////////
    /// Global functions
    ////////////////////////////////////////////
    /// @notice                 Artifact minting function
    /// @param _id              Artifact ID
    /// @param _salt            Salt parameter
    /// @param _signature       Signature
    function mint(uint _id, bytes32 _salt, bytes calldata _signature) public {
        require(tokenInfo[_id].mintEnabled, "Mint: Mint paused");
        require(stakingContract.calculateTotalAndPendingRewards(msg.sender) >= tokenInfo[_id].tokensRequired * 1e18, "Mint: Staking requirement not reached");
        require(verifySignatureForAddress(msg.sender, _id, _salt, _signature), "Mint: Signature invalid");
        require(!tokenInfo[_id].hasClaimedReward[msg.sender], "Mint: Already claimed");
        
        tokenInfo[_id].hasClaimedReward[msg.sender] = true;
        _mint(msg.sender, _id, 1, "");
    }

    /// @notice                 Signature verification function
    /// @param _address         User address
    /// @param _id              Artifact ID
    /// @param _salt            Salt parameter
    /// @param _signature       Signature
    function verifySignatureForAddress(address _address, uint _id, bytes32 _salt, bytes calldata _signature) public view returns (bool) {
        return _verify(_hash(_address, _id, _salt), _signature);
    }

    /// @notice                 Retreives the URI for an Artifact
    /// @param _id              Artifact ID
    function uri(uint256 _id) public view virtual override returns (string memory) {
        return tokenInfo[_id].tokenURI;
    }

    ///////////////////////////////////////////
    /// Internal functions
    ///////////////////////////////////////////
    function _hash(address _address, uint _id, bytes32 _salt) internal view returns (bytes32) {
        return keccak256(abi.encode(_address, address(this), _id, _salt));
    }

    function _verify(bytes32 hash, bytes memory token) internal view returns (bool) {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token) internal pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }

    ///////////////////////////////////////////
    /// Getter functions
    ///////////////////////////////////////////
    /// @notice                 Check if an address has already claimed a reward item
    /// @param _user            A wallet address
    /// @param _id              ID of the token
    function hasUserClaimed(address _user, uint _id) public view returns (bool) {
        return tokenInfo[_id].hasClaimedReward[_user];
    }

    ///////////////////////////////////////////
    /// Owner functions
    ///////////////////////////////////////////
    /// @notice                 Set the public key of the signature signer
    /// @param _newSigner       New signer public key
    function setSigner(address _newSigner) external onlyOwner {
        _signer = _newSigner;
    }

    /// @notice                 Set a new staking contract address
    /// @param _contract        New staking contract address
    function setStakingContract(address _contract) external onlyOwner {
        stakingContract = StakingContract(_contract);
    }

    /// @notice                 Set the token amount earned from staking needed to claim an Artifact
    /// @param _id              Artifact ID
    /// @param _tokenAmount     Amount of tokens (whole)
    function setTokensRequired(uint _id, uint _tokenAmount) external onlyOwner {
        tokenInfo[_id].tokensRequired = _tokenAmount;
    }

    /// @notice                 Set the tokenURI for an Artifact
    /// @param _id              Artifact ID
    /// @param _newUri          New tokenURI
    function setTokenUri(uint _id, string calldata _newUri) external onlyOwner {
        tokenInfo[_id].tokenURI = _newUri;
    }

    /// @notice                 Toggle minting status for an Artifact
    /// @param _id              Artifact ID
    /// @param _status          true/false
    function setMintEnabled(uint _id, bool _status) external onlyOwner {
        tokenInfo[_id].mintEnabled = _status;
    }

    /// @notice                 Mint an Artifact to the owner
    /// @param _id              ID of the Artifact
    function mintAdmin(uint _id) external onlyOwner {
        _mint(msg.sender, _id, 1, "");
    }
}