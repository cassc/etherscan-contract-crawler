// SPDX-License-Identifier: GPL-3.0
/*
 * @title Social Kongs NFT
 */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SocialKongs is ERC721, Ownable {
    using Strings for uint256;

    using Counters for Counters.Counter;

    Counters.Counter public _tokenIds;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedURI;

    uint256 public cost = 0.02 ether;

    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 20;
    uint256 public freeThreshold = 3000;

    bool public paused = true;
    mapping(address => bool) public whitelisted;

    mapping(address => uint256) public freeMinted;
    mapping(address => uint256) public publicMinted;

    bool public publicSale = false;

    address payable public address1;
    address payable public address2;
    address payable public address3;
    address payable public address4;
    address payable public address5;

    constructor(string memory _initBaseURI) ERC721("Social Kongs", "SKNG") {
        setBaseURI(_initBaseURI);

        address1 = payable(0x7C856DACb2C1793392e3D93E0d1eADF17DdAaF1b);
        address2 = payable(0x672b4691821b0eC202395f66e86dcB3C83Ce0Dd0);
        address3 = payable(0xC5D343a95135E8D271626FAB1Ed2Ac1484244373);
        address4 = payable(0x7d57a82Af8bE85229Fa108dE5887163580440A7f);
        address5 = payable(0x1235C8066214b80Dd86FA12b8566E5E4A8AbDdb7);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function currentCost() public view returns (uint256) {
        if (_tokenIds.current() > freeThreshold) {
            return cost;
        } else {
            return 0;
        }
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused);
        require(_mintAmount > 0);

        // if not public sale require owner or whitelist to mint
        if (!publicSale) {
            require(
                msg.sender == owner() || whitelisted[msg.sender] == true,
                "You are not owner or whitelisted!"
            );
        }

        if (_tokenIds.current() < freeThreshold) {
            require(freeMinted[msg.sender] != 1, "You can mint only 1 NFT");
        }

        require(
            publicMinted[msg.sender] + _mintAmount <= maxMintAmount,
            "You can mint only 20 NFTs"
        );
        require(_tokenIds.current() + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            if (whitelisted[msg.sender] != true) {
                require(msg.value >= currentCost() * _mintAmount);
            }
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            if (_tokenIds.current() <= freeThreshold) {
                freeMinted[msg.sender] = 1;
            }
            if (_tokenIds.current() <= freeThreshold) {
                publicMinted[msg.sender] += _mintAmount;
            }

            _safeMint(msg.sender, _tokenIds.current() + 1);
            _tokenIds.increment();
        }
    }

    function count() public view returns (uint256) {
        return _tokenIds.current();
    }

    function updateCurrentSupplyForTesting(uint256 _value) public onlyOwner {
        _tokenIds._value = _value;
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _tokenIds.current();
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount &&
            currentTokenId <= _tokenIds.current()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(
        string memory _newNotRevealedURI
    ) public onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setFreeThreshold(uint256 _freeThreshold) public onlyOwner {
        freeThreshold = _freeThreshold;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setPause() public onlyOwner {
        paused = !paused;
    }

    function setPublicSale() public onlyOwner {
        publicSale = !publicSale;
    }

    function addWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function addWhitelistUsers(address[] memory _users) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            whitelisted[_users[i]] = true;
        }
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        uint256 amount1 = (balance * 30) / 100;
        uint256 amount2 = (balance * 20) / 100;
        uint256 amount3 = (balance * 45) / 100;
        uint256 amount4 = (balance * 3) / 100;
        uint256 amount5 = (balance * 2) / 100;

        address1.transfer(amount1);
        address2.transfer(amount2);
        address3.transfer(amount3);
        address4.transfer(amount4);
        address5.transfer(amount5);
    }

    function withdrawToken(address _address) public onlyOwner {
        IERC20 token = IERC20(_address);
        uint256 balance = token.balanceOf(address(this));

        uint256 amount1 = (balance * 30) / 100;
        uint256 amount2 = (balance * 20) / 100;
        uint256 amount3 = (balance * 45) / 100;
        uint256 amount4 = (balance * 3) / 100;
        uint256 amount5 = (balance * 2) / 100;

        token.transfer(address1, amount1);
        token.transfer(address2, amount2);
        token.transfer(address3, amount3);
        token.transfer(address4, amount4);
        token.transfer(address5, amount5);
    }
}