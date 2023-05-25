// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./eReentrantGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

interface Component {
    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function burn(uint256 tokenId) external;
}

contract Psilocybin is
    ERC721("Psilocybin", "Psilocybin"),
    IERC2981,
    Ownable,
    nonReentrant
{
    using Strings for uint256;

    string public baseUnrevealedURI =
        "ipfs://QmU6jskNygLHYQ88P1oeJcxJyLKYRACGFiyHcuYNuRGPsg";
    string public baseRevealedURI = "";

    uint16 internal tokenCount = 1;
    uint8 public royaltyDivisor = 20;
    bool public saleIsActive = false;
    bool public isRevealed = false;
    bool private isOpenSeaProxyActive = true;

    address internal openSeaProxyRegistryAddress =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    mapping(uint256 => bool) public pappUsed;

    Component public PAPP =
        Component(0xC8E1de8Dc39a758C7a50F659b53F787e0F1398BD);
    Component public C1 = Component(0x5501024dDb740266Fa0d69d19809EC86dB5E3f8b);
    Component public C2 = Component(0xA7B6cb932EEcACd956454317d59c49AA317e3C57);
    Component public C3 = Component(0xc8Cc20febE260C62A9717534442D4E499F9DE741);

    /**
     * SETTERS
     */

    function setBaseURI(
        string memory _unrevealedUri,
        string memory _revealedUri
    ) external onlyOwner {
        baseUnrevealedURI = _unrevealedUri;
        baseRevealedURI = _revealedUri;
    }

    function setComponents(
        Component _papp,
        Component _c1,
        Component _c2,
        Component _c3
    ) external onlyOwner {
        PAPP = _papp;
        C1 = _c1;
        C2 = _c2;
        C3 = _c3;
    }

    function switchSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function switchIsRevealed() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function setRoyaltyDivisor(uint8 _divisor) external onlyOwner {
        royaltyDivisor = _divisor;
    }

    function setIsOpenSeaProxyActive(bool _isActive) external onlyOwner {
        isOpenSeaProxyActive = _isActive;
    }

    function setOpenSeaProxyAddress(address _address) external onlyOwner {
        openSeaProxyRegistryAddress = _address;
    }

    /**
     * USER FUNCTIONS
     */

    function totalSupply() external view returns (uint256) {
        return tokenCount - 1;
    }

    /** @dev User will need to approve all burning before calling this function */
    function claim(
        uint256 _PAPPid,
        uint256 _C1id,
        uint256 _C2id,
        uint256 _C3id
    ) external reentryLock {
        require(saleIsActive, "Sale is not active");
        require(PAPP.ownerOf(_PAPPid) == msg.sender, "Invalid PAPP");
        require(!pappUsed[_PAPPid], "PAPP has been used");

        try C1.burn(_C1id) {} catch Error(string memory reason) {
            revert(string(abi.encodePacked("C1: ", reason)));
        }
        try C2.burn(_C2id) {} catch Error(string memory reason) {
            revert(string(abi.encodePacked("C2: ", reason)));
        }
        try C3.burn(_C3id) {} catch Error(string memory reason) {
            revert(string(abi.encodePacked("C3: ", reason)));
        }

        pappUsed[_PAPPid] = true;

        _mint(msg.sender, tokenCount++);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /** @dev This will be used to mint extra C3 for giveaways */
    function ownerMint(uint256 _amount) external onlyOwner {
        uint16 _tokenCount = tokenCount;
        for (uint256 i; i < _amount; i++) {
            _mint(msg.sender, _tokenCount++);
        }
        tokenCount = _tokenCount;
    }

    /**
     * OVERRIDES
     */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            isRevealed
                ? string(abi.encodePacked(baseRevealedURI, tokenId.toString()))
                : string(abi.encodePacked(baseUnrevealedURI));
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * VIEW FUNCTIONS
     */

    /** @dev See {IERC2981-royaltyInfo} */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (
            0x218B622bbe4404c01f972F243952E3a1D2132Dec,
            salePrice / royaltyDivisor
        );
    }

    function checkBalances(address _a)
        external
        view
        returns (
            uint256 _PAPP,
            uint256 _C1,
            uint256 _C2,
            uint256 _C3
        )
    {
        _PAPP = PAPP.balanceOf(_a);
        _C1 = C1.balanceOf(_a);
        _C2 = C2.balanceOf(_a);
        _C3 = C3.balanceOf(_a);
    }
}

/***************************************
 * @author: 🍖                         *
 * @team:   Asteria                     *
 ****************************************/