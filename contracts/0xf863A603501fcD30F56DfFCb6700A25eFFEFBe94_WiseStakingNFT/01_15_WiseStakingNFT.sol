// SPDX-License-Identifier: WISE

pragma solidity =0.8.19;

import "./IWise.sol";
import "./Helper.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * author hamman247
 * review vitally.eth
 */

contract WiseStakingNFT is ERC721Enumerable, Helper {

    string public baseURI;
    string public baseExtension = ".json";

    bool locked = false;

    IWise public immutable wiseToken;
    mapping(uint256 => bytes16) public NFTStake;

    modifier onlyTokenOwner(
        uint256 _tokenId
    ) {
        require(
            msg.sender == ownerOf(_tokenId),
            "WiseStakingNFT: NOT_OWNER"
        );
        _;
    }

    modifier nonReentrant() {
        require(
            locked == false,
            "WiseStakingNFT: LOCKED"
        );
        locked = true;
        _;
        locked = false;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        IWise _wiseTokenAddress
    )
        ERC721(
            _name,
            _symbol
        )
    {
        wiseToken = _wiseTokenAddress;

        setBaseURI(
            _initBaseURI
        );
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    /**
     * @dev Creates NFT stake using WISE token, requires approval.
     */
    function mint(
        uint256 _amount,
        uint64 _lockDays,
        address _referrer
    )
        external
        nonReentrant
    {
        uint256 tokenId = _totalSupply();

        wiseToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        (
            NFTStake[tokenId]
            ,
            ,
        ) = wiseToken.createStake(
            _amount,
            _lockDays,
            _referrer
        );

        _safeMint(
            msg.sender,
            tokenId
        );
    }

    /**
     * @dev Creates NFT stake using ETH, you will send ETH.
     */
    function mintWithEth(
        uint64 _lockDays,
        address _referrer
    )
        external
        payable
        nonReentrant
    {
        uint256 tokenId = _totalSupply();

        (
            NFTStake[tokenId]
            ,
            ,
        ) = wiseToken.createStakeWithETH{
            value: msg.value
        }(
            _lockDays,
            _referrer
        );

        _safeMint(
            msg.sender,
            tokenId
        );
    }

    /**
     * @dev Creates NFT stake using any ERC20 convertable to ETH/WISE.
     */
    function mintWithToken(
        address _tokenAddress,
        uint256 _amount,
        uint64 _lockDays,
        address _referrer
    )
        external
        nonReentrant
    {
        uint256 tokenId = _totalSupply();

        IWise(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        IWise(_tokenAddress).approve(
            address(wiseToken),
            type(uint256).max
        );

        (
            NFTStake[tokenId]
            ,
            ,
        ) = wiseToken.createStakeWithToken(
            _tokenAddress,
            _amount,
            _lockDays,
            _referrer
        );

        _safeMint(
            msg.sender,
            tokenId
        );
    }

    /**
     * @dev Closes NFT stake and burns the token.
     */
    function burn(
        uint256 _tokenId
    )
        external
        onlyTokenOwner(_tokenId)
    {
        _burn(
            _tokenId
        );

        uint256 interest = wiseToken.endStake(
            NFTStake[_tokenId]
        );

        wiseToken.transfer(
            msg.sender,
            interest
        );

        uint256 remaining = wiseToken.balanceOf(
            address(this)
        );

        wiseToken.transfer(
            msg.sender,
            remaining
        );
    }

    /**
     * @dev Returns NFT stakes of owner
     */
    function walletOfOwner(
        address _owner
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(
            _owner
        );

        uint256[] memory tokenIds = new uint256[](
            ownerTokenCount
        );

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(
                _owner,
                i
            );
        }

        return tokenIds;
    }

    /**
     * @dev Allows to update base target for MetaData.
     */
    function setBaseURI(
        string memory _newBaseURI
    )
        public
        onlyOwner
    {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    )
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /**
     * @dev Return path to MetaData uri
     */
    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId) == true,
            "WiseStakingNFT: WRONG_TOKEN"
        );

        string memory currentBaseURI = _baseURI();

        if (bytes(currentBaseURI).length == 0) {
            return "";
        }

        return string(
            abi.encodePacked(
                currentBaseURI,
                _toString(_tokenId),
                baseExtension
            )
        );
    }
}