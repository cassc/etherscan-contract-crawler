// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IOmniERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import "../interfaces/IOmniseaPointsRepository.sol";
import { MintParams, Asset } from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenFactory
 * @author Omnisea
 * @custom:version 1.0
 * @notice TokenFactory is ERC721 minting service.
 *         Contract is responsible for validating and executing the function that creates (mints) a NFT.
 *         Enables delegation of cross-chain minting via Omnichain Router which abstracts underlying cross-chain messaging.
 *         messaging protocols such as LayerZero and Axelar Network.
 *         It is designed to avoid burn & mint mechanism to keep NFT's non-fungibility, on-chain history, and references to contracts.
 *         It supports cross-chain actions instead of ERC721 "transfer", and allows simultaneous actions from many chains,
 *         without requiring the NFT presence on the same chain as the user performing the action (e.g. mint).
 */
contract TokenFactory is IOmniApp, Ownable, ReentrancyGuard {

    event OmReceived(string srcChain, address srcOA);
    event Minted(address collAddr, address rec, uint256 quantity);
    event Paid(address rec);
    event Locked(address rec, uint256 amount, address asset);
    event Refunded(address rec);
    event NewRefund(address collAddr, address spender, uint256 sum);

    error InvalidPrice(address collAddr, address spender, uint256 paid, uint256 quantity);
    error InvalidCreator(address collAddr, address cre);
    error InvalidAsset(string collAsset, string paidAsset);

    uint256 private constant ACTION_MINT = 1;
    uint256 private constant ACTION_WITHDRAW = 2;

    IOmnichainRouter public omnichainRouter;
    IOmniseaPointsRepository public pointsRepository;
    mapping(address => mapping(string => mapping(address => uint256))) public refunds;
    mapping(address => mapping(string => uint256)) public mints;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    mapping(string => Asset) public assets;
    uint256 private _fee;
    address private _feeManager;
    address private _redirectionsBudgetManager;

    /**
     * @notice Sets the contract owner, feeManager address, router, and indicates source chain name for mappings.
     *
     * @param _router A contract that handles cross-chain messaging used to extend ERC721 with omnichain capabilities.
     */
    constructor(IOmnichainRouter _router) {
        chainName = "Ethereum";
        _feeManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        omnichainRouter = _router;
    }

    function setRouter(IOmnichainRouter _router) external onlyOwner {
        omnichainRouter = _router;
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee <= 5);
        _fee = fee;
    }

    function setFeeManager(address _newManager) external onlyOwner {
        _feeManager = _newManager;
    }

    function setRedirectionsBudgetManager(address _newManager) external onlyOwner {
        _redirectionsBudgetManager = _newManager;
    }

    function setChainName(string memory _chainName) external onlyOwner {
        chainName = _chainName;
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
     * @notice Checks the presence of the selected remote User Application ("OA").
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function isOA(string memory remoteChainName, address remoteOA) public view returns (bool) {
        return remoteOA != address(0) && remoteChainToOA[remoteChainName] == remoteOA;
    }

    /**
     * @notice Adds ERC20 (asset) support as the minting payment currency.
     *
     * @param asset Address of the supported ERC20.
     * @param assetName Name of the asset used for the mapping purpose.
     * @param decimals Token decimals.
     */
    function addAsset(address asset, string memory assetName, uint256 decimals) external onlyOwner {
        require(asset != address(0));
        assets[assetName] = Asset(IERC20(asset), decimals);
    }

    function setPointsRepository(IOmniseaPointsRepository _pointsRepository) external onlyOwner {
        pointsRepository = _pointsRepository;
    }

    /**
     * @notice Handles the ERC721 minting logic.
     *         Validates data and checks if minting is allowed.
     *         If price for mint is set, it initiates payment processing.
     *         Delegates task to the Omnichain Router based on the varying chainName and dstChainName.
     *
     * @param params See MintParams struct in ERC721Structs.sol.
     */
    function mintToken(MintParams calldata params) public payable nonReentrant {
        require(params.quantity > 0, "!quantity");
        require(bytes(params.dstChainName).length > 0 && params.coll != address(0));

        if (keccak256(bytes(params.dstChainName)) == keccak256(bytes(chainName))) { // TODO: test just params.dstChainName == chainName ??
            IOmniERC721 collection = IOmniERC721(params.coll);

            _handlePoints(collection, params.quantity);

            uint256 price = collection.mintPrice();
            uint256 quantityPrice = price * params.quantity;
            if (price > 0) {
                processMintPayment(quantityPrice, msg.sender, collection.creator(), false, assets[collection.assetName()]);
            }
            collection.mint(msg.sender, params.quantity, params.merkleProof);
            emit Minted(params.coll, msg.sender, params.quantity);
            return;
        }
        if (params.mintPrice > 0) {
            processMintPayment((params.mintPrice * params.quantity), msg.sender, address(this), true, assets[params.assetName]);
        }
        bytes memory payload = _getMintPayload(params.coll, params.mintPrice, params.creator, params.assetName, params.quantity, params.merkleProof);
        _omniAction(payload, params.dstChainName, params.gas, params.redirectFee);
    }

    /**
     * @notice Handles the incoming tasks from other chains received from Omnichain Router.
     *         Validates User Application.
     *         actionType == 1: mint.
     *         actionType != 1: withdraw (See payout / refund).

     * @notice Prevents throwing supply exceeded error when mint transactions from at least 2 chains are racing.
     *         srcChain isn't aware of supply exceeding risk when initiating a transaction because it doesn't know about
     *         pending cross-chain transactions from other chains. If a price for mint is specified and funds were locked
     *         on the srcChain, the minting user will be eligible for a refund (unlocking and return of the funds).
     *         This way, it syncs the minting logic state between each chain.
     *
     * @param _payload Encoded MintParams data.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcOA);
        require(isOA(srcChain, srcOA), "!OA");
        (uint256 actionType, address coll, bool minted, uint256 paid, address rec, address cre, string memory assetName, uint256 quantity, bytes32[] memory merkleProof)
        = abi.decode(_payload, (uint256, address, bool, uint256, address, address, string, uint256, bytes32[]));

        if (actionType == ACTION_WITHDRAW) {
            withdraw(rec, cre, paid, assetName, minted);
            return;
        }
        IOmniERC721 collection = IOmniERC721(coll);

        _handlePoints(collection, quantity);

        uint256 price = collection.mintPrice();
        uint256 quantityPrice = price * quantity;
        uint256 maxSupply = collection.maxSupply();

        if (cre != collection.creator()) revert InvalidCreator(coll, cre);

        if (price > 0) {
            if (paid != quantityPrice) revert InvalidPrice(coll, rec, paid, quantity);
            if (keccak256(bytes(assetName)) != keccak256(bytes(collection.assetName()))) revert InvalidAsset(collection.assetName(), assetName);

            if (maxSupply > 0 && (collection.totalMinted() + quantity) > maxSupply) {
                refunds[coll][srcChain][rec] += quantityPrice;
                emit NewRefund(coll, rec, quantityPrice);
                return;
            }
        }

        collection.mint(rec, quantity, merkleProof);
        mints[coll][srcChain] += quantity;
        emit Minted(coll, rec, quantity);
    }

    /**
     * @notice Refund if mint failed due to supply exceeded on cross-chain mint (funds locked on dstChain).
     *
     * @param collectionAddress The address of the ERC721 collection.
     * @param dstChainName Name of the remote chain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function refund(address collectionAddress, string memory dstChainName, uint256 gas, uint256 redirectFee) external payable nonReentrant {
        IOmniERC721 collection = IOmniERC721(collectionAddress);
        uint256 amount = refunds[collectionAddress][dstChainName][msg.sender];
        require(collection.mintPrice() > 0 && amount > 0);
        refunds[collectionAddress][dstChainName][msg.sender] = 0;
        _omniAction(_getWithdrawPayload(collectionAddress, false, amount, collection.assetName()), dstChainName, gas, redirectFee);
    }

    /**
     * @notice Payout creator earnings (funds from minting locked on dstChain).
     *
     * @param collectionAddress The address of the ERC721 collection.
     * @param dstChainName Name of the remote chain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function getEarned(address collectionAddress, string memory dstChainName, uint256 gas, uint256 redirectFee) external payable nonReentrant {
        IOmniERC721 collection = IOmniERC721(collectionAddress);
        uint256 price = collection.mintPrice();
        uint256 amount = mints[collectionAddress][dstChainName] * price;
        require(price > 0 && amount > 0 && msg.sender == collection.creator());
        mints[collectionAddress][dstChainName] = 0;
        _omniAction(_getWithdrawPayload(collectionAddress, true, amount, collection.assetName()), dstChainName, gas, redirectFee);
    }

    function withdrawOARedirectFees() external onlyOwner {
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
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
    function _omniAction(bytes memory payload, string memory dstChainName, uint256 gas, uint256 redirectFee) private {
        require(isOA(dstChainName, remoteChainToOA[dstChainName]), "!OA");

        omnichainRouter.send{value : msg.value}(dstChainName, remoteChainToOA[dstChainName], payload, gas, msg.sender, redirectFee);
    }

    /**
     * @notice If same chain, pays creator immediately. If different chains, locks funds for future payout/refund action.
     *
     * @param price Price for a quantity of ERC721 tokens to mint.
     * @param spender The spender address.
     * @param receiver The collection creator address.
     * @param isLock Cross-chain minting requires locking funds for the future withdraw action.
     * @param asset Asset used for minting.
     */
    function processMintPayment(uint256 price, address spender, address receiver, bool isLock, Asset memory asset) internal {
        IERC20 token = asset.token;
        uint256 inWei = (price * 10**asset.decimals);
        require(token.allowance(spender, address(this)) >= inWei);

        if (isLock) {
            token.transferFrom(spender, receiver, inWei);
            emit Locked(receiver, inWei, address(token));
            return;
        }

        token.transferFrom(spender, receiver, inWei * (100 - _fee) / 100);
        if (_fee > 0) {
            token.transferFrom(spender, _feeManager, inWei * _fee / 100);
        }
        emit Paid(receiver);
    }

    /**
     * @notice Withdraws funds locked during cross-chain mint. Payout creator if minted, refund spender if failed.
     *
     * @param refundee The refundee address.
     * @param creator The creator address.
     * @param price The price for single ERC721 mint.
     * @param assetName ERC20 minting price currency name.
     * @param isPayout If true pay creator, if false refund spender.
     */
    function withdraw(address refundee, address creator, uint256 price, string memory assetName, bool isPayout) private nonReentrant {
        Asset memory asset = assets[assetName];
        IERC20 token = asset.token;
        uint256 inWei = (price * 10**asset.decimals);

        if (inWei == 0) {
            return;
        }

        if (isPayout) {
            token.transfer(creator, inWei * (100 - _fee) / 100);
            if (_fee > 0) {
                token.transfer(_feeManager, inWei * _fee / 100);
            }
            emit Paid(creator);

            return;
        }
        token.transfer(refundee, inWei);
        emit Refunded(refundee);
    }

    function addCollectionPoints(address _collection, uint256 _quantity) external {
        require(address(pointsRepository) != address(0), "!pointsRepository");
        IOmniERC721 collection = IOmniERC721(_collection);
        pointsRepository.subtract(msg.sender, _quantity);
        collection.addPoints(_quantity);
    }

    /**
     * @notice Encodes data for cross-chain minting execution.
     *
     * @param collectionAddress The collection address.
     * @param price The price for single ERC721 mint.
     * @param creator The creator address.
     * @param assetName ERC20 minting price currency name.
     */
    function _getMintPayload(address collectionAddress, uint256 price, address creator, string memory assetName, uint256 quantity, bytes32[] memory merkleProof) private view returns (bytes memory) {
        return abi.encode(ACTION_MINT, collectionAddress, true, (price * quantity), msg.sender, creator, assetName, quantity, merkleProof);
    }

    /**
     * @notice Encodes data for cross-chain withdraw (payout/refund) execution.
     *
     * @param collectionAddress The collection address.
     * @param isPayout If true payout creator, if false refund spender.
     * @param amount The ERC20 amount to withdraw.
     */
    function _getWithdrawPayload(address collectionAddress, bool isPayout, uint256 amount, string memory assetName) private view returns (bytes memory) {
        return abi.encode(ACTION_WITHDRAW, collectionAddress, isPayout, amount, msg.sender, msg.sender, assetName, 0); // TODO: MUst add bytes32[] merkleProof
    }

    function _handlePoints(IOmniERC721 _collection, uint256 _quantity) private {
        if (_collection.points() <= 0) {
            return;
        }
        require(address(pointsRepository) != address(0), "!pointsRepository");

        uint256 addedPoints = (_collection.points() / _collection.maxSupply()) * _quantity;
        pointsRepository.add(msg.sender, addedPoints);
    }

    receive() external payable {}
}