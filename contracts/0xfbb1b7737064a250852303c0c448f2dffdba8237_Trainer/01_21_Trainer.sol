// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
contract Trainer is ERC721AUpgradeable, ERC721ABurnableUpgradeable, ERC721AQueryableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {

    //#region Setup
    using StringsUpgradeable for uint256;

    //Flags
    bool public saleActive;
    bool public wardrobeChangesActive;
    bool public transferAllowed;
    bool public rewardsActive;

    //Constants
    uint8 public MAX_MINTS_PER_ADDRESS;

    //Pricing
    uint256 public wardrobeChangePrice;

    //Token URI
    string public baseURI;

    //Mappings
    mapping (uint256 => uint256[]) public collectedMetamon;

    //Collected Rewards mapping
    //Trainer id => Reward type => Reward id
    mapping(uint256 => mapping (uint16 => uint256[])) public collectedRewards;

    //Inactive Rewards mapping
    //Reward type => Reward id => inactive status
    mapping(uint16 => mapping (uint256 => bool)) public inactiveRewards;

    //Payable withdraw address
    address payable public withdrawAddress;

    //Coupon for security
    struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

    //Signer
    address private signer;

    //Events
    event ReceivedEth(address _sender, uint256 _value);
    event WardrobeChange(address indexed _sender, uint256 indexed _tokenId);
    event TrainerCreated(address indexed _minter, uint256 indexed _tokenId);
    event MetamonCollected(uint256 indexed _tokenId, uint256 indexed _metamonId);
    event RewardCollected(uint256 indexed _tokenId, uint16 indexed _rewardType, uint256 indexed _rewardId);

    //Special event as part of EIP-4906 emit when metadata is updated to auto refresh marketplace metadata
    event MetadataUpdate(uint256 _tokenId);

    //Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant METAMON_ROLE = keccak256("METAMON_ROLE");
    bytes32 public constant REWARD_ROLE = keccak256("REWARD_ROLE");
    //#endregion

    //Initialize function for proxy
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("MiniMetamon Trainer", "MMM-Trainer");
        __ERC721ABurnable_init();
        __ERC721AQueryable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __trainer_init();

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(TRANSFER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(WITHDRAW_ROLE, ADMIN_ROLE);
        _setRoleAdmin(METAMON_ROLE, ADMIN_ROLE);
        _setRoleAdmin(REWARD_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    fallback() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    receive() external payable {
        emit ReceivedEth(msg.sender, msg.value);
    }

    //Initialize function for this contract which sets the defaults for state variables
    function __trainer_init() internal initializer {
        MAX_MINTS_PER_ADDRESS = 1;
        wardrobeChangePrice = 0.01 ether;
        baseURI = "https://minimetamon-trainers-metadata.s3.us-east-2.amazonaws.com/output/";
    }
    
    ///////////////////////////////////////////////////////////////////////////
    // Mint Function
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Mints one trainer to caller given a valid coupon from mint website.
     * Checks if sale is active.
     * Checks if caller has not already minted a trainer.
     * We allow people to mint and transfer to another address if they want to.
     * @param coupon the valid coupon signed by the signer wallet
     */
    function mintTrainer(Coupon memory coupon) external {
        require(saleActive, "Sale must be active to mint");
        require(balanceOf(msg.sender) + 1 <= MAX_MINTS_PER_ADDRESS, "You already have a trainer on this address!");
        require(_isVerifiedCoupon(_createMessageDigest(msg.sender),coupon), "You must mint from the minimetamon website!");

        _safeMint(msg.sender, 1);
        emit TrainerCreated(msg.sender, _totalMinted());
    }

    /**
     * Verifies coupon was signed by the signer wallet
     * @param digest The digest of the message to be signed
     * @param coupon The coupon to be verified
     */
    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
		address _signer = ecrecover(digest,coupon.v,coupon.r,coupon.s);
		require(_signer != address(0),'Invalid signature');
		return _signer == signer;
	}

    /**
     * Creates the message digest to be checked against the coupon
     * @param _address The caller address to be encoded in the message digest
     */
    function _createMessageDigest(address _address) internal pure returns (bytes32) {
		return keccak256(
			abi.encodePacked(
				"\x19Ethereum Signed Message:\n32",
				keccak256(abi.encodePacked(_address))
			)
		);
	}

    ///////////////////////////////////////////////////////////////////////////
    // Wardrobe Change Function
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Allows the owner of a trainer to change the wardrobe of their trainer.
     * Emits an event which is used to update the metadata of the trainer through update pipeline.
     * Checks if wardrobe changes are active.
     * Checks if caller has enough ether to make the change.
     * Checks if caller is the owner of the trainer.
     * Checks if trainer is not burned.
     * @param _tokenId The token id of the trainer to change the wardrobe of
     */
    function wardrobeChange(uint256 _tokenId) external payable {
        require(wardrobeChangesActive, "Wardrobe changes must be active to make the change");
        require(msg.value >= wardrobeChangePrice, "Not enough ether to make wardrobe change!");      
        TokenOwnership memory ownership = explicitOwnershipOf(_tokenId);
        require(ownership.addr == msg.sender, "You cannot change the wardrobe of a trainer you do not own!");
        require(!ownership.burned, "You cannot change the wardrobe of a burned trainer!");
        emit WardrobeChange(msg.sender, _tokenId);
        emit MetadataUpdate(_tokenId);
    }

    /**
     * Called by metamon contract to update list of metamon collected by trainer.
     * Checks if caller is metamon contract.
     * Checks if trainer exists.
     * Metamon contract checks if dex id is valid before calling.
     * @param _trainerTokenId the trainer token id to update the list for
     * @param _metamonDexId the dex id of the metamon collected
     */
    function collectedNewMetamon(uint256 _trainerTokenId, uint256 _metamonDexId) external onlyRole(METAMON_ROLE) {
        require(_exists(_trainerTokenId), "Trainer does not exist");
        collectedMetamon[_trainerTokenId].push(_metamonDexId);
        emit MetamonCollected(_trainerTokenId, _metamonDexId);
    }

    /**
     * Obtains the dex ids of metamon collected by a trainer
     * @param _trainerTokenId the trainer token id to get the list of metamon for
     */
    function getCollectedMetamon(uint256 _trainerTokenId) external view returns (uint256[] memory) {
        return collectedMetamon[_trainerTokenId];
    }

    /**
     * Called by contracts that reward trainer, to update list of rewards collected by trainer.
     * Checks if caller contract has reward role.
     * Checks if trainer exists.
     * Checks if rewards are active.
     * Checks if reward is currently claimable.
     * Emits an event which is used to update the metadata of the trainer through update pipeline.
     * @param _trainerTokenId token id of the trainer to update the list for
     * @param rewardType the reward type - for example metamon = 0, wardrobe = 1, item = 2
     * @param rewardId the id of the reward collected - for example dex id of metamon, wardrobe type id or item type id
     */
    function collectedNewReward(uint256 _trainerTokenId, uint16 rewardType, uint256 rewardId) external onlyRole(REWARD_ROLE){
        require(_exists(_trainerTokenId), "Trainer does not exist");
        require(rewardsActive, "Rewards must be active to collect rewards");
        require(!inactiveRewards[rewardType][rewardId], "Reward is not currently claimable");
        collectedRewards[_trainerTokenId][rewardType].push(rewardId);
        emit RewardCollected(_trainerTokenId, rewardType, rewardId);
    }

    /**
     * Obtains the rewards of a trainer by reward types
     * @param trainerTokenId the token id of the trainer to get the rewards for
     * @param _rewardTypes the reward types to get rewards for - for example metamon = 0, wardrobe = 1, item = 2
     */
    function getRewardsByTypes(uint256 trainerTokenId, uint16[] memory _rewardTypes) public view returns(uint256[][] memory) {
        require(_exists(trainerTokenId), "Trainer does not exist");
        uint256[][] memory rewards = new uint256[][](_rewardTypes.length);
        for(uint i = 0; i < _rewardTypes.length; i++) {
            rewards[i] = collectedRewards[trainerTokenId][_rewardTypes[i]];
        }
        return rewards;
    }

    /**
     * Withdraws the balance of the contract to the withdraw address if it exists.
     * If it does not exist, it withdraws to the caller.
     * Checks if caller has withdraw role or admin role.
     * Checks if withdraw address is valid.
     */
    function withdraw() external nonReentrant {
        require(hasRole(WITHDRAW_ROLE, msg.sender) || hasRole(ADMIN_ROLE, msg.sender), "Caller is not a withdrawer");

        uint256 contractBalance = address(this).balance;
        
        if(withdrawAddress == address(0)){
            _withdraw(payable(msg.sender), contractBalance);
        }
        else{
            _withdraw(withdrawAddress, contractBalance);
        }
    }

    /**
     * Internal helper for withdrawing ether from the contract
     * @param _address the address to withdraw to
     * @param _amount the amount to withdraw
     */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * Gets the number of trainers minted for an owner.
     * @param _owner the owner of the trainer to get the number minted for
     */
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    /**
     * Checks if an owner has minted a trainer.
     * @param _owner the address to check for ownership of a trainer
     */
    function trainerOwnership(address _owner) public view returns (bool) {
        return balanceOf(_owner) > 0;
    }

    /**
     * Used by marketplaces to obtain the uri/json file of a particular token id.
     * @param _tokenId the token id to get the uri for
     */
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = baseURI;

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : '';
    }

    /**
     * Part of the ERC721 standard. Transfers token from one address to another.
     * Does not check if receipient is a contract or that they can receive the token.
     * Checks if transfer is allowed.
     * Checks if transferrer is the owner of the token.
     * Check if transferrer has the transfer role.
     * @param from the address to transfer from
     * @param to the address to transfer to
     * @param tokenId the token id to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(hasRole(TRANSFER_ROLE, from) || transferAllowed, "Trainer: transfer is not allowed");
        require(balanceOf(to) == 0, "Trainer: cannot transfer to an existing trainer");
        super.transferFrom(from, to, tokenId);
    }

    /**
     * Part of the ERC721 standard. Safely transfers token from one address to another.
     * Checks if receipient is a contract and that they can receive the token (ERC721Receiver.onERC721Received).
     * Checks if transfer is allowed.
     * Checks if transferrer is the owner of the token.
     * Checks if transferrer has the transfer role.
     * @param from the address to transfer from
     * @param to the address to transfer to
     * @param tokenId the token id to transfer
     * @param _data the extra data to send in transaction
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(hasRole(TRANSFER_ROLE, from) || transferAllowed, "Trainer: transfer is not allowed");
        require(balanceOf(to) == 0, "Trainer: cannot transfer to an existing trainer");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * Burns a trainer token and removes it from the owner's list of trainers.
     * Checks if caller owns a trainer.
     * @param _tokenId the token id to burn
     */
    function burn(uint256 _tokenId) public virtual override {
        require(balanceOf(msg.sender) >= 1, "Caller must own a trainer to burn one!");
        _burn(_tokenId, true);
    }

    /**
     * ERC721AUpgradeable internal function to set the starting token id.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Used to identify the interfaces supported by this contract.
     * @param interfaceId the interface id to check for support
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721AUpgradeable, IERC721AUpgradeable, AccessControlUpgradeable) returns (bool) {
        return 
        ERC721AUpgradeable.supportsInterface(interfaceId) ||
        AccessControlUpgradeable.supportsInterface(interfaceId);
    }
    
    ///////////////////////////////////////////////////////////////////////////
    //#region State Changes
    ///////////////////////////////////////////////////////////////////////////
    
    /**
     * Sets the sale active state of the contract
     * @param _saleActive state to change to
     */
    function setSaleActive(bool _saleActive) external onlyRole(ADMIN_ROLE) {
        saleActive = _saleActive;
    }

    /**
     * Sets the transfer allowed state of the contract
     * @param _transferAllowed state to change to
     */
    function setTransferAllowed(bool _transferAllowed) external onlyRole(ADMIN_ROLE) {
        transferAllowed = _transferAllowed;
    }

    /**
     * Sets the rewards active state of the contract
     * @param _rewardsActive state to change to
     */
    function setRewardsActive(bool _rewardsActive) external onlyRole(ADMIN_ROLE) {
        rewardsActive = _rewardsActive;
    }

    /**
     * Sets a specific status for a particular reward
     * @param _rewardType the reward type - for example metamon = 0, wardrobe = 1, item = 2
     * @param _rewardId the reward id - for example dex id, wardrobe type id, item type id
     * @param _status true - reward is not claimable, false - reward is claimable
     */
    function setSpecificRewardInactiveStatus(uint16 _rewardType, uint256 _rewardId, bool _status) external onlyRole(ADMIN_ROLE) {
        inactiveRewards[_rewardType][_rewardId] = _status;
    }

    /**
     * Sets the wardrobe changes allowed state of the contract
     * @param _wardrobeChangesAllowed state to change to
     */
    function setWardrobeChangesAllowed(bool _wardrobeChangesAllowed) external onlyRole(ADMIN_ROLE) {
        wardrobeChangesActive = _wardrobeChangesAllowed;
    }

    /**
     * Sets the wardrobe change price of the contract
     * @param _WardrobeChangePrice price to change to in wei
     */
    function setWardrobeChangePrice(uint256 _WardrobeChangePrice) external onlyRole(ADMIN_ROLE) {
        wardrobeChangePrice = _WardrobeChangePrice;
    }

    /**
     * Sets the withdrawal address of the contract
     * @param _withdrawAddress address to withdraw to
     */
    function setWithdrawAddress(address payable _withdrawAddress) external onlyRole(ADMIN_ROLE) {
        withdrawAddress = _withdrawAddress;
    }

    /**
     * Sets the max mintable for the contract per address
     * @param _maxMintable number of max mintable
     */
    function setAddressMaxMints(uint8 _maxMintable) external onlyRole(ADMIN_ROLE) {
        MAX_MINTS_PER_ADDRESS = _maxMintable;
    }

    /**
     * Sets the signer address signing coupons on server
     * @param _signer address of the signer
     */
    function setSigner(address _signer) external onlyRole(ADMIN_ROLE) {
        signer = _signer;
    }

    /**
     * Sets the base uri of the contract
     * @param _baseURI base uri to change to
     */
    function setBaseURI(string calldata _baseURI) external onlyRole(ADMIN_ROLE) {
        baseURI = _baseURI;
    }
    //#endregion
}