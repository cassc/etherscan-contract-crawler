// SPDX-License-Identifier: MIT
/**

* MIT License
* ===========
*
* Copyright (c) 2022 OLegacy
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*/

pragma solidity 0.8.13;

import "./utils/Addons.sol";
import "./utils/OwnableUpgradeable.sol";
import "./interfaces/IOToken.sol";
import "./interfaces/IERC20Upgradeable.sol";
import "./utils/ReentrancyGuardUpgradeable.sol";



contract OController is OwnableUpgradeable, Addons, ReentrancyGuardUpgradeable {
    // interfaces
    OTokenInterface public OToken;

    // state variables
    bytes[] public batches;
    bytes[] public burnings;
    uint256 public batchesCount;
    uint256 public burningsCount;
    bool public batchesMigrated;
    bool public burningsMigrated;
    uint256 private tokensBurned;
    uint256 private tokensMinted;
    address public burningAddress;

    // mappings
    mapping(address => bool) public managers;
    mapping(address => mapping(string => bool)) public serviceProvidersWhitelist;
    mapping(address => uint) public burningBalanceOf;
    mapping(bytes => bool) public usedSignatures;

    struct Burning {
        address user;
        address vaultingCompany;
        uint256 amount;
        Order order;
    }

    struct VaultSignedData {
        address vaultingCompany;
        uint256 olgcCount;
        Order order;
    }

    // structs
    struct Batch {
        string batchId;
        Order[] orders;
        uint256 ordersCount;
        uint256 oTokensMinted;
        ProviderConfirmations[] providers;
        MintingBase[] minting;
        uint256 providersCount;
        uint256 timestamp;
    }

    struct Order {
        string name;
        string weightOZ;
    }

    struct Service {
        string name;
        address provider;
    }

    struct Minting {
        address[] receiver;
        uint256[] amount;
    }

    struct MintingBase {
        Order order;
        Minting _minting;
    }

    struct ProviderConfirmations {
        string batchId;
        Order[] orders;
        address minter;
        string role;
        bytes data;
        bytes signature;
    }

    struct adminDataStruct {
        bytes32[] hashes;
        string batchId;
        MintingBase[] _minting;
    }

    // events
    event TokensMintingEvent(address[] addresses, uint256[] amount, bytes32 hash, string batchId, string orderId);
    event BatchEvent(uint256 amount, bytes32 hash, Batch batch);
    event Burned(address _user, uint256 _value);

    // const hashes
    bytes4 public method_burn;
    bytes4 public method_mint;
    bytes4 public method_add_provider;
    bytes4 public method_remove_provider;
    bytes4 public method_replace_provider;
    bytes4 public method_bulk_add_provider;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address token, address _burningAddress, uint256 minted, uint256 burned) public initializer {
        batchesCount = 0;
        burningsCount = 0;
        OToken = OTokenInterface(token);
        batchesMigrated = false;
        burningsMigrated = false;
        tokensMinted = minted;
        tokensBurned = burned;
        burningAddress = _burningAddress;
        __Ownable_init();
        method_burn = bytes4(keccak256("burnTokens(bytes,bytes)"));
        method_mint = bytes4(keccak256("execMinting(bytes,bytes,bytes,bytes)"));
        method_add_provider = bytes4(keccak256("addProvider(string,address,bytes)"));
        method_remove_provider = bytes4(keccak256("removeProvider(string,address,bytes)"));
        method_replace_provider = bytes4(keccak256("replaceProvider(bytes,bytes)"));
        method_bulk_add_provider = bytes4(keccak256("bulkAddProviders(bytes,bytes)"));
    }

    // Modifiers
    modifier canBurn() {
        require(msg.sender == burningAddress, "only burningAddress wallet is allowed");
        _;
    }

    modifier onlyTokenContract() {
        require(msg.sender == address(OToken), "Only Token contract is allowed");
        _;
    }

    modifier onlyNonZeroAddress(address _user) {
        require(_user != address(0), "Zero address not allowed");
        _;
    }

    /**
    * @notice Get current chain id from the env
    */
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // External functions

    function bulkAddManagers(bytes calldata data)
    external onlyOwner nonReentrant returns (bool status)
    {
        address[] memory managersArray = abi.decode(data, (address[]));
        for (uint8 i = 0; i < managersArray.length; i++) {
            managers[managersArray[i]] = true;
        }
        return true;
    }

    /**
     * @notice Function called by token contract wherever tokens are deposited to this contract
     * @dev Only token contract can call.
     * @param _from The number of tokens to be burned
     * @param _value The user corresponding to which tokens are burned
     * @param data The data supplied by token contract. It will be ignored
     */
    function tokenFallback(address _from, uint _value, bytes calldata data) external onlyTokenContract {
        burningBalanceOf[_from] = burningBalanceOf[_from] + _value;
    }

    /**
     * @notice Burns the tokens from users account for physical redemption
     * @dev The amount of tokens burned must be less than or equal to token deposited by user
     * @param _burning The number of tokens to be burned and order data
     * @param _signature The user corresponding to which tokens are burned
     * @return bool true in case of successful burn
     */
    function burnTokens(bytes calldata _burning, bytes calldata _signature) external canBurn nonReentrant returns(bool){
        Burning memory b;
        b = abi.decode(_burning, (Burning));

        VaultSignedData memory v = VaultSignedData(b.vaultingCompany, b.amount, b.order);

        bytes32 _message = keccak256(abi.encode(v, getChainID(), method_burn));
        require(b.vaultingCompany == getSigner(_message, _signature), "Wrong signer");
        require(!usedSignatures[_signature], "Signature was used previously");
        usedSignatures[_signature] = true;
        require(burningBalanceOf[b.user] > 0 && burningBalanceOf[b.user] >= b.amount, "Wrong user or amount to burn");
        burnings.push(abi.encode(b));
        require(OToken.burn(b.amount, bytes32ToString(_message), b.order.name), "Burning failure");
        burningBalanceOf[b.user] = burningBalanceOf[b.user] - b.amount;
        tokensBurned = tokensBurned + b.amount;
        burningsCount = burningsCount + 1;

        emit Burned(b.user, b.amount);
        return true;
    }

    /**
     * @notice Add new provider to the system
     * @dev Check if signer exists in managers mapping and add new provider
     * @param _role provider role
     * @param _provider provider address
     * @param _signature Manager wallet signature
     */
    function addProvider(string calldata _role, address _provider, bytes calldata _signature) external nonReentrant returns (bool status) {
        bytes32 _message = keccak256(abi.encode(_role, _provider, getChainID(), method_add_provider));
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        require(!serviceProvidersWhitelist[_provider][_role], "Service already exists");
        serviceProvidersWhitelist[_provider][_role] = true;
        return true;
    }

    /**
     * @notice Remove provider from the system
     * @dev Check if signer exists in managers mapping and delete existing provider
     * @param _role provider role
     * @param _provider provider address
     * @param _signature Manager wallet signature
     */
    function removeProvider(string calldata _role, address _provider, bytes calldata _signature) external nonReentrant returns (bool status) {
        bytes32 _message = keccak256(abi.encode(_role, _provider, getChainID(), method_remove_provider));
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        require(serviceProvidersWhitelist[_provider][_role], "Service not exists");
        serviceProvidersWhitelist[_provider][_role] = false;
        return true;
    }

    /**
     * @notice Replace provider function
     * @dev Check if signer exists in managers mapping and delete existing provider if it's exists
       and add new provider if it's not added to the mapping
     * @param data encoded array of Service tuple
     * @param _signature Manager wallet signature
     */
    function replaceProvider(bytes calldata data, bytes calldata _signature)
        external nonReentrant returns (bool status)
    {
        bytes32 _message = keccak256(abi.encode(data, getChainID(), method_replace_provider));
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        Service[] memory providersArray = abi.decode(data, (Service[]));
        for (uint8 i = 0; i < providersArray.length; i++) {
            if(serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name]) {
                serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name] = false;
            } else {
                serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name] = true;
            }

        }
        return true;
    }


    /**
     * @notice Bulk add providers function
     * @dev Check if signer exists in managers mapping and add new providers
     * @param data encoded array of Service tuple
     * @param _signature Manager wallet signature
     */
    function bulkAddProviders(bytes calldata data, bytes calldata _signature)
    external nonReentrant returns (bool status)
    {
        bytes32 _message = keccak256(abi.encode(data, getChainID(), method_bulk_add_provider));
        require(validManagerOrAdmin(_signature, _message), "Caller not allowed");
        Service[] memory providersArray = abi.decode(data, (Service[]));
        for (uint8 i = 0; i < providersArray.length; i++) {
            serviceProvidersWhitelist[providersArray[i].provider][providersArray[i].name] = true;
        }
        return true;
    }

    /**
     * @notice Execute OTokens minting process validations
     * @dev Encode payload data and perform providers and minting data validations
     * @param adminData encoded adminDataStruct tuple
     * @param providersData encoded array of ProviderConfirmations tuple
     * @param ordersList encoded array of Order tuple
     * @param _sig Manager wallet signature
     */
    function execMinting(
        bytes calldata adminData,
        bytes calldata providersData,
        bytes calldata ordersList,
        bytes calldata _sig
    ) external nonReentrant returns(bool) {
        ProviderConfirmations[] memory providersArray = abi.decode(providersData, (ProviderConfirmations[]));
        adminDataStruct memory admin = abi.decode(adminData, (adminDataStruct));
        bytes32 _message = keccak256(abi.encode(admin.batchId, getChainID(), method_mint));
        require(validManagerOrAdmin(_sig, _message), "Caller not allowed");
        require(!usedSignatures[_sig], "Signature was used previously");
        usedSignatures[_sig] = true;
        Order[] memory orders = abi.decode(ordersList, (Order[]));
        Batch memory batch;
        batch.batchId = admin.batchId;
        batch.orders = orders;
        require(admin.hashes.length == providersArray.length, "Wrong amount of confirmations");
        verifyProviders(providersArray, admin.hashes);
        batch.providers = providersArray;
        batch.ordersCount = batch.orders.length;
        batch.providersCount = batch.providers.length;

        require(_mint(admin._minting, keccak256(encodeTightlyPacked(admin.hashes)), batch), "something went wrong");

        return true;
    }

    // Public functions

    /**
     * @notice update burning wallet address. This address will be responsible for burning tokens
     * @dev Only owner can call
     * @param _burningAddress The address that is allowed to burn tokens from suspense wallet
     * @return Bool value
     */
    function updateBurningAddress(address _burningAddress)
    external
    onlyOwner
    onlyNonZeroAddress(_burningAddress)
    nonReentrant
    returns (bool)
    {
        burningAddress = _burningAddress;
        return true;
    }

    /**
     * @notice manually add batches
     * @dev Only owner can call
     * @param _batches array of Batch structs
     * @return Bool value
     */
    function addBatches(bytes calldata _batches) external onlyOwner nonReentrant returns(bool) {
        require(!batchesMigrated, "Batches already migrated");
        batchesMigrated = true;
        Batch[] memory _b = abi.decode(_batches, (Batch[]));
        for (uint o=0; o<_b.length;o++) {
            writeStore(_b[o]);
            batchesCount = batchesCount + 1;
        }
        return true;
    }

    /**
     * @notice manually add burnings
     * @dev Only owner can call
     * @param _burnings array of Batch structs
     * @return Bool value
     */
    function addBurnings(bytes calldata _burnings) external onlyOwner returns(bool) {
        require(!burningsMigrated, "Burnings already migrated");
        burningsMigrated = true;
        Burning[] memory _b = abi.decode(_burnings, (Burning[]));
        for (uint o=0; o<_b.length;o++) {
            tokensBurned += _b[o].amount;
            burnings.push(abi.encode(_b[o]));
            burningsCount = burningsCount + 1;
        }
        return true;
    }

    /**
     * @notice Add new manager to the system
     * @param _manager Manager wallet address
     * @return status
     */
    function addManager(address _manager) external onlyOwner returns (bool status) {
        require(!managers[_manager], "Manager already added");
        managers[_manager] = true;
        status = true;
    }

    /**
     * @notice Remove manager from the system
     * @param _manager Manager wallet address
     * @return status
     */
    function removeManager(address _manager) external onlyOwner returns (bool status) {
        require(managers[_manager], "Manager already added");
        managers[_manager] = false;
        status = true;
    }

    /**
     * @notice Owner can transfer out any accidentally sent ERC20 tokens accept OTokens
     * @param _tokenAddress The contract address of ERC-20 compitable token
     * @param _value The number of tokens to be transferred to owner
     */
    function transferAnyERC20Token(address _tokenAddress, uint256 _value) public onlyOwner returns (bool) {
        require (_tokenAddress != address(OToken),"Can not withdraw OTs");
        require(IERC20Upgradeable(_tokenAddress).transfer(owner(), _value), "Transfer failed");
        return true;
    }

    // View functions

    /**
     * @notice Manager signature validator
     * @dev Check if signer exists in managers mapping
     * @param _signature Manager wallet signature
     * @param _message Manager signed message
     * @return Bool value
     */
    function validManagerOrAdmin(bytes calldata _signature, bytes32 _message) public view returns (bool) {
        return (msg.sender == owner() || managers[getSigner(_message, _signature)]);
    }

    function getBatch(uint256 id) external view returns(Batch memory b){
        return abi.decode(batches[id], (Batch));
    }

    function getBurnings(uint256 id) external view returns(Burning memory b){
        return abi.decode(burnings[id], (Burning));
    }

    function getTotalBurned() external view returns(uint256){
        return tokensBurned;
    }

    function getTotalMinted() external view returns(uint256){
        return tokensMinted;
    }

    // Internal functions

    function verifyHashes(bytes32[] memory hashes, bytes32 msgHash) internal pure returns(bool exists) {
        exists = false;
        for(uint8 h=0; h < hashes.length; h++) {
            if(hashes[h] == msgHash) {
                exists = true;
            }
        }
    }

    function verifyProviders(ProviderConfirmations[] memory providersArray, bytes32[] memory hashes) internal view {

        for (uint8 i = 0; i < providersArray.length; i++) {
            bytes32 msgHash = keccak256(abi.encode(
                    providersArray[i].batchId,
                    providersArray[i].minter,
                    providersArray[i].role
                ));
            bool exists = false;
            address signer = getSigner(
                msgHash,
                providersArray[i].signature
            );
            require(
                serviceProvidersWhitelist[signer][providersArray[i].role],
                "Address is not whitelisted"
            );
            exists = verifyHashes(hashes, msgHash);
            require(exists, "one of the messages is wrong");

        }
    }

    /**
     * @notice Execute OTokens minting process
     * @dev Encode payload data and mint tokens
     * @param _minting encoded MintingBase tuple
     * @param orderHash keccak256 hash of providers data hashes
     * @param batch Batch struct that contain current operation data
     */
    function _mint(MintingBase[] memory _minting, bytes32 orderHash, Batch memory batch) internal returns(bool) {
        require(_minting.length == batch.orders.length, "Orders count not match");
        MintingBase[] memory mintArray = _minting;
        for (uint i = 0; i < mintArray.length; i++) {
            require(OToken.bulkMint(mintArray[i]._minting.receiver, mintArray[i]._minting.amount, bytes32ToString(orderHash), mintArray[i].order.name), "something went wrong with minting");
            for(uint m =0; m < mintArray[i]._minting.amount.length; m++) {
                batch.oTokensMinted += mintArray[i]._minting.amount[m];
            }
            emit TokensMintingEvent(mintArray[i]._minting.receiver, mintArray[i]._minting.amount, orderHash, batch.batchId, mintArray[i].order.name);
        }
        batch.minting = _minting;
        batchesCount = batchesCount + 1;
        batch.timestamp = block.timestamp;
        emit BatchEvent(batch.oTokensMinted, orderHash, batch);

        writeStore(batch);
        return true;
    }

    function writeStore(Batch memory batch) internal {
        tokensMinted += batch.oTokensMinted;
        batches.push(abi.encode(batch));
    }

}