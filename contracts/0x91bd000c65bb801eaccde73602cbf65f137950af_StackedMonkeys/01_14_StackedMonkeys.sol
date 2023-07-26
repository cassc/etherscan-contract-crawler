// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/*
STACK                               
    */

contract StackedMonkeys is ERC721URIStorage, Ownable, IERC721Receiver {
    using Strings for uint256;
    event MintStack(address indexed sender, uint256 startWith);

    //uints

    uint256 public totalCount = 3333;
    uint256 public totalMonkeys;
    address public unstackedMonkeeAddress;
    string public baseURI;

    address public staking = address(this);

    //bool
    bool private started;

    //constructor args
    constructor(address _unstackedAddress, string memory baseURI_)
        ERC721("Stacked Monkeys", "EMST")
    {
        unstackedMonkeeAddress = _unstackedAddress;
        baseURI = baseURI_;
    }

    function totalSupply() public view virtual returns (uint256) {
        return totalMonkeys;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : ".json";
    }

    function setTokenURI(uint256 _tokenIds, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(_tokenIds, _tokenURI);
    }

    function startStacking() public onlyOwner {
        started = true;
    }

    function stopStacking() public onlyOwner {
        started = false;
    }

    function devMint(uint256 _times) public onlyOwner {
        emit MintStack(_msgSender(), totalMonkeys + 1);
        for (uint256 i = 0; i < _times; i++) {
            _mint(_msgSender(), 1 + totalMonkeys++);
        }
    }

    function stack(uint256[] calldata _tokenIds) public {
        require(started, "not started");
        require(
            IERC721(unstackedMonkeeAddress).isApprovedForAll(
                _msgSender(),
                address(this)
            ),
            "unstacked monkeys not approved for spending"
        );
        require(_tokenIds.length == 3, "you need 3 unstacked monkeys to stack");
        require(totalMonkeys + 1 <= totalCount, "not enough monkeys");
        for (uint256 i; i < _tokenIds.length; i++) {
            IERC721(unstackedMonkeeAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                _tokenIds[i]
            );
        }
        emit MintStack(_msgSender(), totalMonkeys + 1); //emit a MintStackEvent
        _mint(_msgSender(), 1 + totalMonkeys++);
    }

    function setStakingAddress(address _stakingAddress) public onlyOwner {
        staking = _stakingAddress;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == staking ||
            spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}