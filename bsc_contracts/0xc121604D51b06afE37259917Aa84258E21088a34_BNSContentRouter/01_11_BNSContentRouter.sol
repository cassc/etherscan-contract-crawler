// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RecoverableFunds.sol";
import "./interfaces/IContentRouter.sol";

contract BNSContentRouter is IContentRouter, RecoverableFunds, AccessControl {

    IContentProvider public defaultContentProvider;
    mapping(string => ContentRoute) public contentRoutes;

    bytes32 public constant CONTENT_MANAGER = keccak256("CONTENT_MANAGER");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTENT_MANAGER, msg.sender);
    }

    function setDefaultContentProvider(address newDefaultContentProvider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultContentProvider = IContentProvider(newDefaultContentProvider);
    }

    function setContentOrAddress(string memory name, string memory relativePath, string memory content, ContentType contentType, address contentProvider) override external onlyRole(CONTENT_MANAGER) {
        ContentRoute storage route = contentRoutes[name];
        route.exists = true;
        route.contentType = contentType;
        if (contentType == ContentType.INTERNAL) {
            if (contentProvider != address(0x0)) {
                route.contentProvider = IContentProvider(contentProvider);
            } else if (address(route.contentProvider) == address(0x0)) {
                route.contentProvider = defaultContentProvider;
            }
            route.contentProvider.setContent(name, relativePath, content);
        } else {
            route.contentAddress = content;
        }
    }

    function getContentOrAddress(string memory name, string memory relativePath) override external view returns (ContentType, string memory) {
        ContentType contentType = contentRoutes[name].contentType;
        if (contentType == ContentType.INTERNAL) {
            return (contentType, getContent(name, relativePath));
        } else {
            return (contentType, getContentAddress(name, relativePath));
        }
    }

    function getContent(string memory name, string memory relativePath) public view returns (string memory) {
        ContentRoute memory route = contentRoutes[name];
        require(route.exists, "ContentRouter: Requested name record not found");
        require(route.contentType == ContentType.INTERNAL, "ContentRouter: This method is only used for internal content");
        return IContentProvider(route.contentProvider).getContent(name, relativePath);
    }

    function getContentAddress(string memory name, string memory relativePath) public view returns (string memory) {
        ContentRoute memory route = contentRoutes[name];
        require(route.exists, "ContentRouter: Requested name record not found");
        require(route.contentType == ContentType.EXTERNAL, "ContentRouter: This method is only used for external content");
        return route.contentAddress;
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveTokens(recipient, tokenAddress);
    }

    function retrieveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _retrieveETH(recipient);
    }

}