// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.9.0;

/// Owned collection contract to be deployed from Factory
import "./CreatorNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INichoNFTMarketplace.sol";

/**
 * @title Mock marketplace contract
 * @notice This is a mock contract to test the functionalities of the contract collection
 */
contract CollectionFactory is Ownable{
    // testing purposes, need to change back to 0.05
    uint public constant DEPLOY_FEE = 0.05 ether;

    // marketplace address
    INichoNFTMarketplace public nichonftmarketplaceContract;

    // make sure only collection owner can batch mint
    error InvalidOwner();
    // throw when the deploy fees is not enough
    error InvalidDeployFees();

    // This event will be emited after a new creator contract has been deployed
    // It will be used to interact with Moralis cloud function and store them in Moralis database
    event CollectionDeployed(
        address indexed creator,
        address indexed contract_address,
        string collection_name,
        string collection_id
    );
    // This state variable will store the deployed contract on-chain
    mapping(address => mapping(uint => address)) private database;
    // This will keep track of the creator's collection, as creator can have multiple collections
    mapping(address => uint) private collectionId;

    // check created own collection
    mapping(address => bool) public royaltyFeeAble;

    constructor() {}

    function setMarketplaceContract(
        INichoNFTMarketplace _nichonftMarketplace
    ) onlyOwner external{
        require(address(_nichonftMarketplace) != address(0x0), "Invalid address");
        require(nichonftmarketplaceContract != _nichonftMarketplace, "Marketplace: has been already configured");
        nichonftmarketplaceContract = _nichonftMarketplace;
    }

    /**
     * @notice This function will deploy a brand new contract when creator create a new collection
     *         It will store the deployed address on-chain
     * @dev The collectionId will start from 0
     *      deployFees can be set in the frontend
     * @param _name -> collection name
     *        _symbol -> collection symbol
     *        _deployFees -> base price to create a collection (should be in wei)
     */
    function deploy(string memory _name, string memory _symbol, string memory _collection_id, uint256 _royaltyFee)
        external
        payable
    {
        // creator need to pay 0.05 BNB to create his own collection
        if (msg.value < DEPLOY_FEE) revert InvalidDeployFees();

        uint id = collectionId[msg.sender];
        CreatorNFT nftContract = new CreatorNFT(
            msg.sender,
            address(nichonftmarketplaceContract),
            _name,
            _symbol,
            _royaltyFee
        );

        // register to allow nft contract to list directly
        nichonftmarketplaceContract.setDirectListable(address(nftContract));

        royaltyFeeAble[address(nftContract)] = true;
        database[msg.sender][id] = address(nftContract);
        collectionId[msg.sender]++;

        emit CollectionDeployed(msg.sender, address(nftContract), _name, _collection_id);
    }

    /**
     * Check if royalty fee is applied.
     */
    function checkRoyaltyFeeContract(address _contractAddress) external view returns(bool) {
        return royaltyFeeAble[_contractAddress];
    }

    /**
     * @notice This function will return the deployed contract address
     * @param _creatorAddress -> identify the creator
     *        _collectionId -> identify the collection
     * @return Deployed address to interact with
     */
    function getCreatorContractAddress(
        address _creatorAddress,
        uint _collectionId
    ) public view returns (address) {
        return database[_creatorAddress][_collectionId];
    }

    /**
     * @notice Get the current collection id. It is useful to keep track of how many collection creator have
     * @dev Collection id start from 0
     * @param _creatorAddress -> identify the creator
     * @return A current id of collection ie. 1 => 1 collections deployed
     */
    function getCurrentCollectionId(address _creatorAddress)
        external
        view
        returns (uint)
    {
        return collectionId[_creatorAddress];
    }

    // Withdraw Fee to admin
    function withdrawETH(uint _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Wrong amount");

        payable(msg.sender).transfer(_amount);
    }
}