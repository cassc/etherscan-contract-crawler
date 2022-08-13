/*

                                                             ?
                                                             ??
                                                            ????
                                                          ???????
                                                ,???????????????????
                                         ,??????????????????????????????L
                                     ?????????????????????????????????????'
                                  ???????????????????????????????????
                               ??????????? ,??????        ????????
                             ????????    ????????          ?????
                           .?????       ?????????           "??
                          ????         ????    ?????????W    ?w
                         ???           ???       ????????    J
                         ??           ???????        ??,,????
                        ??             ??????     ??????
                        ?              ???????    ????? ?
                        ?               ????      ?????
                         ??               ??????????????
                           ????L           ???????????
                              ?????????????????????
                                      '??'

*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { Pausable } from "openzeppelin-contracts/contracts/security/Pausable.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";

error Unstarted();
error NonWhitelisted();
error InvalidPrice();
error Minted();
error MaxSupply();
error NotAllowed();
error NonExistentTokenURI();
error WithdrawTransfer();
error Unmatch();

contract TasteTimonials is Ownable, ERC721, Pausable {

    using Strings for uint256;

    uint256 public TOTAL_SUPPLY = 33;
    uint256 public PUBLIC_MINT_PRICE = 0.02 ether;
    uint256 public PRESALE_MINT_PRICE = 0.015 ether;
    string public baseURI;

    uint256 public currentTokenId;
    bool public isPublicMint;
    bool public isPresale;

    mapping(address => bool) public isPublicMinted;
    mapping(address => bool) public whitelisted;

    constructor(
      string memory _name, 
      string memory _symbol, 
      string memory _baseURI
    ) ERC721(_name, _symbol) {
      baseURI = _baseURI;
    }

    modifier isWhitelisted() {
      if(!whitelisted[msg.sender]) {
        revert NonWhitelisted();
      }
      _;
    }
    
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
      if (ownerOf(id) == address(0)) {
        revert NonExistentTokenURI();
      }

      return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, id.toString())) : '';
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
      baseURI = _newURI;
    }

    function setPresale(bool _status) external onlyOwner {
      isPresale = _status;
    }

    function setPublicMint(bool _status) external onlyOwner {
      isPublicMint = _status;
    }

    function setCollectionDetails(uint256 _presalePrice, uint256 _publicPrice, uint256 _totalSupply) external onlyOwner {
      PRESALE_MINT_PRICE = _presalePrice;     
      PUBLIC_MINT_PRICE = _publicPrice;
      TOTAL_SUPPLY = _totalSupply;
    }

    function setWhitelist(address[] calldata _address, bool[] calldata _status) external onlyOwner {
      if (_address.length != _status.length) {
        revert Unmatch();
      }

      for (uint8 i; i < _address.length; ++i) {
        whitelisted[_address[i]] = _status[i];
      }
    }

    function pause() external virtual onlyOwner {
      _pause();
    }

    function unpause() external virtual onlyOwner {
      _unpause();
    }

    function withdraw(address payable _receiver) external onlyOwner {
      uint256 balance = address(this).balance;
      (bool success, ) = _receiver.call{value: balance}("");
      if (!success) {
        revert WithdrawTransfer();
      }
    }

    function mint() external payable whenNotPaused {
      if (!isPublicMint) {
        revert Unstarted();
      }
      if(msg.sender != tx.origin) {
        revert NotAllowed();
      }
      if (isPublicMinted[msg.sender]) {
        revert Minted();
      }
      if (msg.value < PUBLIC_MINT_PRICE) {
        revert InvalidPrice();
      }

      unchecked {
        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > TOTAL_SUPPLY) {
          revert MaxSupply();
        }
        _mint(msg.sender, newTokenId);
        isPublicMinted[msg.sender] = true;
      }
    }

    function whitelistMint() external payable isWhitelisted whenNotPaused {
      if (!isPresale) {
        revert Unstarted();
      }
      if (msg.value < PRESALE_MINT_PRICE) {
        revert InvalidPrice();
      }

      unchecked {
        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > TOTAL_SUPPLY) {
            revert MaxSupply();
        }
        _mint(msg.sender, newTokenId);
        whitelisted[msg.sender] = false;
      }
    }

    function devMint(uint256 _quantity) external onlyOwner {
      unchecked {
        for (uint8 i; i < _quantity; ++i) {
          uint256 newTokenId = ++currentTokenId;
          if (newTokenId > TOTAL_SUPPLY) {
              revert MaxSupply();
          }
          _mint(msg.sender, newTokenId);
        }
      }
    }
}