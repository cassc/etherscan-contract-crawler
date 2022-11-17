//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Policy.sol";
import "../interfaces/ICNSController.sol";

contract TokenGatedPolicy is Policy {
    constructor(
        address _ensAddr,
        address _baseRegistrarAddr,
        address _resolverAddr,
        address _cnsControllerAddr
    ) Policy(_ensAddr, _baseRegistrarAddr, _resolverAddr, _cnsControllerAddr) {
        require(_ensAddr != address(0), "Invalid address");
        require(_baseRegistrarAddr != address(0), "Invalid address");
        require(_resolverAddr != address(0), "Invalid address");
        require(_cnsControllerAddr != address(0), "Invalid address");
    }

    mapping(bytes32 => address) public tokenGated;
    mapping(address => mapping(uint256 => address)) internal historyMints;

    function setTokenGated(bytes32 _node, address _tokenAddress) public {
        require(
            cnsController.isDomainOwner(
                cnsController.getTokenId(_node),
                msg.sender
            ),
            "Only owner can set token gated"
        );
        _setTokenGated(_node, _tokenAddress);
    }

    function _setTokenGated(bytes32 _node, address _tokenAddress) internal {
        tokenGated[_node] = _tokenAddress;
    }

    function permissionCheck(
        bytes32 _node,
        address _account,
        uint256 _tokenId
    ) public view virtual returns (bool) {
        bool _permission = false;
        if (tokenGated[_node] == address(0)) {
            return false;
        }

        uint256 _holdingBalance = getTokenHoldingBalance(_node, _account);

        if (
            _holdingBalance > 0 &&
            isNFTOwner(tokenGated[_node], _tokenId, _account)
        ) {
            _permission = true;
        }

        return _permission;
    }

    function getTokenHoldingBalance(bytes32 _node, address _account)
        internal
        view
        returns (uint256)
    {
        return IERC721(tokenGated[_node]).balanceOf(_account);
    }

    function isMint(address _tokenGated, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return historyMints[_tokenGated][_tokenId] == msg.sender;
    }

    function isNFTOwner(
        address _tokenAddress,
        uint256 _tokenId,
        address _account
    ) public view returns (bool) {
        return _account == IERC721(_tokenAddress).ownerOf(_tokenId);
    }

    function checkMintWithtokenId(
        address _tokenAddr,
        uint256 _tokenId,
        address _account
    ) external view returns (bool) {
        if (historyMints[_tokenAddr][_tokenId] == _account) {
            return false;
        }
        return true;
    }

    function registerSubdomain(
        string memory _subdomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        uint256 _NFTtokenId
    ) public {
        address tokengated = tokenGated[_node];
        bool permission = true;

        //check NFT holding balance
        require(
            permissionCheck(_node, msg.sender, _NFTtokenId),
            "Not holding token"
        );

        //check minted with tokenId
        if (isMint(tokengated, _NFTtokenId)) {
            permission = false;
        } else {
            permission = true;
        }
        require(permission, "You don't have permission to register subdomain");

        //register subdomain
        cnsController.registerSubdomain(
            _subdomainLabel,
            _node,
            _subnode,
            msg.sender
        );
        //add history mint
        historyMints[tokengated][_NFTtokenId] = msg.sender;
    }

    function subDomainForOwner(
        string memory _subdomainLabel,
        bytes32 _node,
        bytes32 _subnode
    ) public {
        require(cnsController.getOwner(_node) == msg.sender, "Not Owner");
        cnsController.registerSubdomain(
            _subdomainLabel,
            _node,
            _subnode,
            msg.sender
        );
    }

    function unRegisterSubdomain(
        string memory _subDomainLabel,
        bytes32 _node,
        bytes32 _subnode,
        uint256 _NFTtokenId
    ) public {
        require(
            cnsController.isDomainOwner(
                cnsController.getTokenId(_node),
                msg.sender
            ) || cnsController.getSubDomainOwner(_subnode) == msg.sender,
            "Not owner"
        );
        cnsController.unRegisterSubdomain(_subDomainLabel, _node, _subnode);
        delete historyMints[tokenGated[_node]][_NFTtokenId];
    }
}