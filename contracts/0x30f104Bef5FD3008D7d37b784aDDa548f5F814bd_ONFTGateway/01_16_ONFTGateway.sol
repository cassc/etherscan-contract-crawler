// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import "../interfaces/IONFTCopy.sol";
import "./ONFTCopy.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ONFTGateway is IOmniApp, Ownable {

    event OmReceived(string srcChain, address srcOA);
    event Transferred(address srcCollection, uint256 tokenId, address owner);
    event Locked(address collection, uint256 tokenId, address owner);

    IOmnichainRouter public omnichainRouter;
    mapping(address => mapping(uint256 => address)) public locked; // collection -> tokenId -> owner
    // Emergency unlock in case of a failed tx on the dstChain
    mapping(address => mapping(uint256 => bool)) public forceUnlockRequests; // collection -> tokenId -> isRequested
    mapping(address => address) public copyToOriginal;
    mapping(address => address) public originalToCopy;
    mapping(address => mapping(uint256 => bool)) public isCopy;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    address private _owner;
    address private _redirectionsBudgetManager;

    /**
     * @notice Sets the contract owner, feeManager address, router, and indicates source chain name for mappings.
     *
     * @param _router A contract that handles cross-chain messaging used to extend ERC721 with omnichain capabilities.
     */
    constructor(IOmnichainRouter _router) {
        _owner = msg.sender;
        chainName = "Ethereum";
        omnichainRouter = _router;
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

    function setRouter(IOmnichainRouter _router) external onlyOwner {
        omnichainRouter = _router;
    }

    function setRedirectionsBudgetManager(address _newManager) external onlyOwner {
        _redirectionsBudgetManager = _newManager;
    }

    /**
     * @notice Sets the remote Omnichain Applications ("OA") addresses to meet omReceive() validation.
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function setOA(string memory remoteChainName, address remoteOA) external onlyOwner {
        remoteChainToOA[remoteChainName] = remoteOA;
    }

    /**
     * @notice Checks the presence of the selected remote Omnichain Application ("OA").
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function isOA(string memory remoteChainName, address remoteOA) public view returns (bool) {
        return remoteChainToOA[remoteChainName] == remoteOA;
    }

    /**
     * @notice Sends the ERC-721 to the destination chain
     *
     * @param collection ERC721 collection contract.
     * @param tokenId ID of the token
     * @param dstChainName OmnichainRouter-specific destination chain name.
     * @param gas Gas limit of the transaction executed on the destination chain.
     * @param redirectFee OmnichainRouter-specific gas limit of the redirection transaction on the redirect chain.
     */
    function sendTo(IERC721Metadata collection, uint256 tokenId, string memory dstChainName, uint256 gas, uint256 redirectFee) public payable {
        require(bytes(dstChainName).length > 0);
        address collAddress = address(collection);
        require(collAddress != address(0), "!ADDRESS");
        require(tokenId > 0, "!ID");
        require(_isContract(collAddress), "!EXISTS");
        require(collection.ownerOf(tokenId) == msg.sender, "!OWNER");

        if (isCopy[collAddress][tokenId]) {
            IONFTCopy copy = IONFTCopy(collAddress);
            _send(_getPayload(collection, copyToOriginal[collAddress], tokenId), dstChainName, gas, redirectFee);
            copy.burn(tokenId);
            isCopy[collAddress][tokenId] = false;

            return;
        }

        collection.transferFrom(msg.sender, address(this), tokenId);
        locked[collAddress][tokenId] = msg.sender;
        emit Locked(collAddress, tokenId, msg.sender);
        _send(_getPayload(collection, collAddress, tokenId), dstChainName, gas, redirectFee);
    }

    /**
     * @notice Handles the incoming task from other chains received from Omnichain Router.
     *         Validates Omnichain Application.

     * @notice Mints an NFT copy (ONFTCopy) or recovers the original NFT (locked on the source chain) and transfers to
     *         its owner.
     *
     * @param _payload Encoded bytes payload.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcOA);
        require(isOA(srcChain, srcOA));
        (address originalAddress, uint256 tokenId, string memory tokenURI, address owner, string memory name, string memory symbol) = abi.decode(_payload, (address, uint256, string, address, string, string));

        if (locked[originalAddress][tokenId] != address(0)) {
            IERC721 original = IERC721(originalAddress);
            delete locked[originalAddress][tokenId];
            original.transferFrom(address(this), owner, tokenId);
            emit Transferred(originalAddress, tokenId, owner);

            return;
        }

        if (originalToCopy[originalAddress] != address(0)) {
            IONFTCopy copy = IONFTCopy(originalToCopy[originalAddress]);
            copy.mint(owner, tokenId, tokenURI);
            isCopy[originalToCopy[originalAddress]][tokenId] = true;
        } else {
            ONFTCopy copy = new ONFTCopy(name, symbol);
            copy.mint(owner, tokenId, tokenURI);
            address copyAddress = address(copy);
            isCopy[copyAddress][tokenId] = true;
            originalToCopy[originalAddress] = copyAddress;
            copyToOriginal[copyAddress] = originalAddress;
        }
        emit Transferred(originalAddress, tokenId, owner);
    }

    /**
     * @notice Withdraws all the Omnichain Application's redirect fees collected from end-users in case of required redirections
    */
    function withdrawOARedirectFees() external onlyOwner {
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
    }

    function requestForceUnlock(address _collection, uint256 _tokenId) external {
        require(locked[_collection][_tokenId] == msg.sender, '!locked OR !owner');
        forceUnlockRequests[_collection][_tokenId] = true;
    }

    function forceUnlock(address _collection, uint256 _tokenId) external onlyOwner {
        require(locked[_collection][_tokenId] != address(0), '!locked');
        require(forceUnlockRequests[_collection][_tokenId], '!requested');
        forceUnlockRequests[_collection][_tokenId] = false;
        IERC721 unlocked = IERC721(_collection);
        unlocked.transferFrom(address(this), locked[_collection][_tokenId], _tokenId);
        delete locked[_collection][_tokenId];
    }

    /**
     * @notice Delegates cross-chain task to the Omnichain Router.
     *
     * @param payload Data required for the task execution on the dstChain.
     * @param dstChainName Name of the remote chain.
     * @param gas Gas limit set for the function execution on the dstChain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function _send(bytes memory payload, string memory dstChainName, uint256 gas, uint256 redirectFee) private {
        omnichainRouter.send{value : msg.value}(dstChainName, remoteChainToOA[dstChainName], payload, gas, msg.sender, redirectFee);
    }

    /**
     * @notice Encodes the data to the bytes payload for the cross-chain message.
     *
     * @param collection ERC-721 NFT collection.
     * @param original Address of the original NFT collection.
     * @param tokenId ID of the token.
     */
    function _getPayload(IERC721Metadata collection, address original, uint256 tokenId) private view returns (bytes memory) {
        string memory tokenURI = collection.tokenURI(tokenId);

        return abi.encode(original, tokenId, tokenURI, msg.sender, collection.name(), collection.symbol());
    }

    /**
     * @notice Checks if the given address is a contract.
     */
    function _isContract(address collection) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(collection) }
        return size > 0;
    }

    receive() external payable {}
}