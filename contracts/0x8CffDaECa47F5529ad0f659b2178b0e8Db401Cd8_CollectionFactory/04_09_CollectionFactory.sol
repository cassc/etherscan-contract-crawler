// SPDX-License-Identifier: MIT
// omnisea-contracts v1.1

pragma solidity ^0.8.7;

import "../interfaces/ICollectionsRepository.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import "../interfaces/IOmniseaPointsRepository.sol";
import { CreateParams } from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CollectionFactory
 * @author Omnisea
 * @custom:version 1.0
 * @notice CollectionFactory is ERC721 collection creation service.
 *         Contract is responsible for validating and executing the function that creates ERC721 collection.
 *         Enables delegation of cross-chain collection creation via Omnichain Router which abstracts underlying cross-chain messaging.
 *         messaging protocols such as LayerZero and Axelar Network.
 *         With the TokenFactory contract, it is designed to avoid burn & mint mechanism to keep NFT's non-fungibility,
 *         on-chain history, and references to contracts. It supports cross-chain actions instead of ERC721 "transfer",
 *         and allows simultaneous actions from many chains, without requiring the NFT presence on the same chain as
 *         the user performing the action (e.g. mint).
 */
contract CollectionFactory is IOmniApp, Ownable {
    event OmReceived(string srcChain, address srcOA);

    address public repository;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    ICollectionsRepository private _collectionsRepository;
    IOmnichainRouter public omnichainRouter;
    IOmniseaPointsRepository public pointsRepository;
    address private _redirectionsBudgetManager;

    /**
     * @notice Sets the contract owner, router, and indicates source chain name for mappings.
     *
     * @param _router A contract that handles cross-chain messaging used to extend ERC721 with omnichain capabilities.
     */
    constructor(IOmnichainRouter _router) {
        chainName = "Ethereum";
        omnichainRouter = _router;
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

    /**
     * @notice Sets the Collection Repository responsible for creating ERC721 contract and storing reference.
     *
     * @param repo The CollectionsRepository contract address.
     */
    function setRepository(address repo) external onlyOwner {
        _collectionsRepository = ICollectionsRepository(repo);
        repository = repo;
    }

    function setRouter(IOmnichainRouter _router) external onlyOwner {
        omnichainRouter = _router;
    }

    function setRedirectionsBudgetManager(address _newManager) external onlyOwner {
        _redirectionsBudgetManager = _newManager;
    }

    function setChainName(string memory _chainName) external onlyOwner {
        chainName = _chainName;
    }

    function setPointsRepository(IOmniseaPointsRepository _pointsRepository) external onlyOwner {
        pointsRepository = _pointsRepository;
    }

    /**
     * @notice Handles the ERC721 collection creation logic.
     *         Validates data and delegates contract creation to repository.
     *         Delegates task to the Omnichain Router based on the varying chainName and dstChainName.
     *
     * @param params See CreateParams struct in ERC721Structs.sol.
     */
    function create(CreateParams calldata params) public payable {
        require(bytes(params.name).length >= 2);

        if (params.points > 0) {
            require(address(pointsRepository) != address(0), "!pointsRepository");
            pointsRepository.subtract(msg.sender, params.points);
        }

        if (keccak256(bytes(params.dstChainName)) == keccak256(bytes(chainName))) {
            _collectionsRepository.create(params, msg.sender);
            return;
        }

        require(isOA(params.dstChainName, remoteChainToOA[params.dstChainName]), "!OA");

        omnichainRouter.send{value : msg.value}(
            params.dstChainName,
            remoteChainToOA[params.dstChainName],
            abi.encode(params, msg.sender),
            params.gas,
            msg.sender,
            params.redirectFee
        );
    }

    /**
     * @notice Handles the incoming ERC721 collection creation task from other chains received from Omnichain Router.
     *         Validates User Application.

     * @param _payload Encoded CreateParams data.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcOA);
        require(isOA(srcChain, srcOA), "!OA");
        (CreateParams memory params, address creator) = abi.decode(_payload, (CreateParams, address));
        _collectionsRepository.create(
            params,
            creator
        );
    }

    /**
     * @notice Sets the remote Omnichain Applications ("OA") addresses to meet omReceive() validation.
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function setOA(string calldata remoteChainName, address remoteOA) external onlyOwner {
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

    function withdrawOARedirectFees() external onlyOwner {
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
    }

    receive() external payable {}
}