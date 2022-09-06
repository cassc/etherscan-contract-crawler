// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./ERC721Enumerable_Minimal.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract IStaker {
    enum TokenType { _gen, _comp, Psilocybin }
    struct TokenInfo { address owner; uint256 timeStaked; }
    mapping(TokenType => mapping(uint256 => TokenInfo)) public tokenInfo;
}

interface IPsilocybin is IERC721 {
    function burn(uint256 tokenId) external;
}

contract DE_MP is ERC721Enumerable, IERC2981, Ownable {
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint8 public royaltyDivisor = 20;
    uint256 public remainingTeamReserved = 211;
    bool public saleIsActive = false;
    bool private isOpenSeaProxyActive = true;

    ProxyRegistry internal openSeaProxyRegistry;

    mapping(uint256 => bool) public psilocybinUsed;

    IPsilocybin public PSILOCYBIN_CONTRACT;
    IERC721 public METAVERSE_CONTRACT;
    IERC721 public IRL_CONTRACT;
    IStaker public STAKING_CONTRACT;

    constructor(address _psilo, address _meta, address _irl, address _staker, string memory _uri) ERC721("Motus Perpetuus", "DE_MP") {
        PSILOCYBIN_CONTRACT = IPsilocybin(_psilo);
        METAVERSE_CONTRACT = IERC721(_meta);
        IRL_CONTRACT = IERC721(_irl);
        STAKING_CONTRACT = IStaker(_staker);
        _setBaseURI(_uri);
    }

    // -------------- //
    //     SETTERS    //
    // -------------- //

    function setBaseURI(string calldata _uri) external onlyOwner {
        _setBaseURI(_uri);
    }

    function switchSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setRoyaltyDivisor(uint8 _divisor) external onlyOwner {
        royaltyDivisor = _divisor;
    }

    function setIsOpenSeaProxyActive(bool _isActive) external onlyOwner {
        isOpenSeaProxyActive = _isActive;
    }

    function setOpenSeaProxyAddress(address _address) external onlyOwner {
        openSeaProxyRegistry = ProxyRegistry(_address);
    }

    // -------------- //
    // USER FUNCTIONS //
    // -------------- //

    /**
     * Mints 1 DE_MP after using a 'Psilocybin' and buring either a 'Metaverse Pass' or 'IRL Pass'
     * @param _useMeta chooses to burn either 'Metaverse Pass' (true) or 'IRL Pass' (false)
     */
    function claim(uint256 _psiloId, uint256 _metaId, uint256 _irlId, bool _useMeta) external {
        require(saleIsActive, "Sale is not active");
        require(!psilocybinUsed[_psiloId], "Psilocybin already used");
        (address stakingOwner, ) = STAKING_CONTRACT.tokenInfo(IStaker.TokenType.Psilocybin, _psiloId);
        require(PSILOCYBIN_CONTRACT.ownerOf(_psiloId) == msg.sender || stakingOwner == msg.sender, "Invalid Psilocybin owner");

        if (_useMeta) {
            try METAVERSE_CONTRACT.transferFrom(msg.sender, DEAD_ADDRESS, _metaId) {} catch Error(string memory reason) {
                revert(string(abi.encodePacked("META: ", reason)));
            }
        } else {
            try IRL_CONTRACT.transferFrom(msg.sender, DEAD_ADDRESS, _irlId) {} catch Error(string memory reason) {
                revert(string(abi.encodePacked("IRL: ", reason)));
            }
        }

        psilocybinUsed[_psiloId] = true;
        _mint(msg.sender, totalSupply());
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /** Mints 211 extra DE_MP for giveaways/airdrops */
    function ownerMint(uint256 _amount) external onlyOwner {
        require(_amount < remainingTeamReserved + 1, "Will exceed reserved amount");
        remainingTeamReserved -= _amount;

        uint256 _tokenCount = totalSupply();
        for (uint256 i = 0; i < _amount; ) {
            _mint(msg.sender, _tokenCount + i);
            unchecked { ++i; }
        }
    }

    // -------------- //
    //      VIEW      //
    // -------------- //

    function checkBalance(address _a) external view 
        returns(uint256 _psilo, uint256 _meta, uint256 _irl) 
    {
        _psilo = PSILOCYBIN_CONTRACT.balanceOf(_a);
        _meta = METAVERSE_CONTRACT.balanceOf(_a);
        _irl = IRL_CONTRACT.balanceOf(_a);
    }

    // -------------- //
    //    OVERRIDES   //
    // -------------- //

    function isApprovedForAll(address owner, address operator)
        public view override(ERC721, IERC721)
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        if (isOpenSeaProxyActive) {
            return address(openSeaProxyRegistry.proxies(owner)) == operator;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_)) : "";
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (
            0x218B622bbe4404c01f972F243952E3a1D2132Dec,
            salePrice / royaltyDivisor
        );
    }
}

/***************************************
 * @author: 🍖                         *
 * @team:   Asteria                     *
 ****************************************/