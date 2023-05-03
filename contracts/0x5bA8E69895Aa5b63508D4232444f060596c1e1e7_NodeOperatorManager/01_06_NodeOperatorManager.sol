// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../src/interfaces/INodeOperatorManager.sol";
import "../src/interfaces/IAuctionManager.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NodeOperatorManager is INodeOperatorManager, Ownable {
    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    event OperatorRegistered(uint64 totalKeys, uint64 keysUsed, bytes ipfsHash);
    event MerkleUpdated(bytes32 oldMerkle, bytes32 indexed newMerkle);

    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------

    address public auctionManagerContractAddress;
    bytes32 public merkleRoot;

    // user address => OperaterData Struct
    mapping(address => KeyData) public addressToOperatorData;
    mapping(address => bool) private whitelistedAddresses;
    mapping(address => bool) public registered;

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Registers a user as a operator to allow them to bid
    /// @param _merkleProof the proof verifying they are whitelisted
    /// @param _ipfsHash location of all IPFS data stored for operator
    /// @param _totalKeys The number of keys they have available, relates to how many validators they can run
    function registerNodeOperator(
        bytes32[] calldata _merkleProof,
        bytes memory _ipfsHash,
        uint64 _totalKeys
    ) public {
        require(!registered[msg.sender], "Already registered");
        
        KeyData memory keyData = KeyData({
            totalKeys: _totalKeys,
            keysUsed: 0,
            ipfsHash: abi.encodePacked(_ipfsHash)
        });

        addressToOperatorData[msg.sender] = keyData;

        _verifyWhitelistedAddress(msg.sender, _merkleProof);
        registered[msg.sender] = true;
        emit OperatorRegistered(
            keyData.totalKeys,
            keyData.keysUsed,
            _ipfsHash
        );
    }

    /// @notice Fetches the next key they have available to use
    /// @param _user the user to fetch the key for
    /// @return the ipfs index available for the validator
    function fetchNextKeyIndex(
        address _user
    ) external onlyAuctionManagerContract returns (uint64) {
        KeyData storage keyData = addressToOperatorData[_user];
        uint64 totalKeys = keyData.totalKeys;
        require(
            keyData.keysUsed < totalKeys,
            "Insufficient public keys"
        );

        uint64 ipfsIndex = keyData.keysUsed;
        keyData.keysUsed++;
        return ipfsIndex;
    }

    /// @notice Updates the merkle root whitelists have been updated
    /// @dev merkleroot gets generated in JS offline and sent to the contract
    /// @param _newMerkle new merkle root to be used for bidding
    function updateMerkleRoot(bytes32 _newMerkle) external onlyOwner {
        bytes32 oldMerkle = merkleRoot;
        merkleRoot = _newMerkle;

        emit MerkleUpdated(oldMerkle, _newMerkle);
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  GETTERS   ---------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice gets the number of keys the user has, used or un-used
    /// @param _user the user to fetch the data for
    /// @return totalKeys the number of keys the user has
    function getUserTotalKeys(
        address _user
    ) external view returns (uint64 totalKeys) {
        totalKeys = addressToOperatorData[_user].totalKeys;
    }

    /// @notice gets the number of keys the user has left to use
    /// @param _user the user to fetch the data for
    /// @return numKeysRemaining the number of keys the user has remaining
    function getNumKeysRemaining(
        address _user
    ) external view returns (uint64 numKeysRemaining) {
        KeyData storage keyData = addressToOperatorData[_user];

        numKeysRemaining =
            keyData.totalKeys - keyData.keysUsed;
    }

    /// @notice gets if the user is whitelisted
    /// @dev used in the auction contract to verify when a user bids that they are indeed whitelisted
    /// @param _user the user to fetch the data for
    /// @return whitelisted bool value if they are whitelisted or not
    function isWhitelisted(
        address _user
    ) public view returns (bool whitelisted) {
        whitelisted = whitelistedAddresses[_user];
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  SETTERS   ---------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Sets the auction contract address for verification purposes
    /// @dev Set manually due to circular dependencies
    /// @param _auctionContractAddress address of the deployed auction contract address
    function setAuctionContractAddress(
        address _auctionContractAddress
    ) public onlyOwner {
        require(auctionManagerContractAddress == address(0), "Address already set");
        require(_auctionContractAddress != address(0), "No zero addresses");
        auctionManagerContractAddress = _auctionContractAddress;
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    function _verifyWhitelistedAddress(
        address _user,
        bytes32[] calldata _merkleProof
    ) internal returns (bool whitelisted) {
        whitelisted = MerkleProof.verify(
            _merkleProof,
            merkleRoot,
            keccak256(abi.encodePacked(_user))
        );
        if (whitelisted) {
            whitelistedAddresses[_user] = true;
        }
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier onlyAuctionManagerContract() {
        require(
            msg.sender == auctionManagerContractAddress,
            "Only auction manager contract function"
        );
        _;
    }
}