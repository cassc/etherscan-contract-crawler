// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/*

OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOO                                                                        OOOO
OOOO   OOOOO                                                        OOOOO   OOOO
OOOO  OOOO                                                            OOOO  OOOO
OOOO  OOOO                                                            OOOO  OOOO
OOOO  OOOOOOO                                                      OOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOO                            OOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOO                  OOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOO              OOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOO            OOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOOO          OOOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
BBBB  BBBBBBBBBBB BBBBB   BBBBBBBBBB        BBBBBBBBBB   BBBBB BBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBB         BBBBBBBBBBB        BBBBBBBBBBB        BBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBBBBB BBBBBBBBBBBBBBBB        BBBBBBBBBBBBBBBB BBBBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBB      BBBBBB   BBBBB        BBBBB   BBBBBB      BBBBBBBBBB  BBBB
BBBB      BBBBB      BBBBB    BBBBB          BBBBB    BBBBB      BBBBB      BBBB
BBBB              BBBBBB     BBBBB            BBBBB     BBBBBB              BBBB
BBBB                       BBBBBB              BBBBBB                       BBBB
BBBB                     BBBBBB                  BBBBBB                     BBBB
BBBB                    BBBBB                      BBBBB                    BBBB
BBBB                   BBBBB  BBBBBBB      BBBBBBB  BBBBB                   BBBB
BBBB                    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                    BBBB
BBBB                      BBBBBBB     BBBB     BBBBBBB                      BBBB
EEEE                                                                        EEEE
EEEE                EEEE                               EEEEE                EEEE
EEEE               EEEEEE                              EEEEEE               EEEE
EEEE              EEEEEEE                              EEEEEEE              EEEE
EEEE            EEEEE            EEE        EEE            EEEEE            EEEE
EEEE            EE          EEEEEEEEEEEEEEEEEEEEEEEE          EE            EEEE
EEEE                   EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE                   EEEE
EEEE                  EEEEEEEE       EEEEEE       EEEEEEEE                  EEEE
EEEE  EE                EEEEEEEE                EEEEEEEE                EE  EEEE
EEEE  EE                    EEEEEEEEE      EEEEEEEE                     EE  EEEE
EEEE  EEE                         EEEEEEEEEEEE                         EEE  EEEE
EEEE  EEEE                           EEEEEE                           EEEE  EEEE
YYYY                                                                        YYYY
YYYY            YY                                            YY            YYYY
YYYY            YYYYY                                      YYYYY            YYYY
YYYY  YYY        YYYYYYYY                              YYYYYYYY        YYY  YYYY
YYYY  YYYYY       YYYYYYYY                            YYYYYYYY       YYYYY  YYYY
YYYY  YYYYYYYY   YYYYYYYYYY                          YYYYYYYYYY   YYYYYYYY  YYYY
YYYY  YYYYYYYYYYYYYYYYYYYYYYYYY                  YYYYYYYYYYYYYYYYYYYYYYYYY  YYYY
YYYY   YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY   YYYY
YYYY                                                                        YYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

 */


interface IdgnRgn {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function balanceOf(address addr) external returns (uint256);
}

contract Wrapper is ERC721URIStorage, IERC721Receiver, Ownable, PaymentSplitter {
    using ECDSA for bytes32;
    uint256 private _tokenIds;
    address public dgnRgnAddr;
    address public signerIpfsLinks;
    mapping(address => WrappedToken) wrappedTokensByAddress;
    mapping(uint256 => WrappedToken) wrappedTokensByTokenId;
    address[] internal _tokens = [address(0x0)];
	  uint256 public constant PRICE = 0.03 ether;


    struct WrappedToken {
      uint256[] stakedTokens;
      bool wrapped;
      uint256 id;
    }
    WrappedToken wt;

    struct MintPayload {
        string ipfsLink; bytes hash;
      }

  function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    constructor(address _signerAddr, address[] memory _payees, uint256[] memory _shares) ERC721("OBEY DGN/RGN Collected", "OBEYDGC") PaymentSplitter(_payees, _shares) payable {
      signerIpfsLinks = _signerAddr;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0x0) && to != address(0x0)) {
          _tokens[tokenId] = to;
        }
    }

    function setDgnRgnAddr(address _addr) public onlyOwner {
       dgnRgnAddr = _addr;
    }

    function setSigner(address _addr) public onlyOwner {
       signerIpfsLinks = _addr;
    }

    function concatUintToString(uint256[] memory numbers) private pure returns (string memory) {
        bytes memory output;

        for (uint256 i = 0; i < numbers.length; i++) {
            output = abi.encodePacked(output, Strings.toString(numbers[i]), ',');
        }

        return string(output);
    }

    function stake(address from, uint256[] memory tokens) public {
      require(from == msg.sender, "You should call this function with your own address.");
      require(IdgnRgn(dgnRgnAddr).balanceOf(msg.sender) > 0, "You should own at least 2 DGN/RGN NFTs.");
      if (wrappedTokensByAddress[from].stakedTokens.length == 0) {
        wrappedTokensByAddress[from] = wt;
      }
      for (uint i=0; i < tokens.length; i++) {
        IdgnRgn(dgnRgnAddr).transferFrom(from, address(this), tokens[i]);
        _stakeNft(from, tokens[i]);
        }
    }

    function unstake_by_address(address to) public {
      require(msg.sender == to, "You cannot unstake other's tokens.");
      for (uint256 i = 0; i < wrappedTokensByAddress[to].stakedTokens.length; i++) {
        address ownerOfDgnRgnToken = IdgnRgn(dgnRgnAddr).ownerOf(wrappedTokensByAddress[to].stakedTokens[i]);
        require( ownerOfDgnRgnToken == address(this), "The token is not owned by the contract.");
        require( ownerOfDgnRgnToken != to, "The token is owned by the to address.");
        IdgnRgn(dgnRgnAddr).transferFrom(address(this), msg.sender, wrappedTokensByAddress[to].stakedTokens[i]);
      }
      delete wrappedTokensByAddress[to].stakedTokens;
    }

    function _unstake_by_tokenId(uint256 tokenId) private {
      for (uint256 i = 0; i < wrappedTokensByTokenId[tokenId].stakedTokens.length; i++) {
        address ownerOfDgnRgnToken = IdgnRgn(dgnRgnAddr).ownerOf(wrappedTokensByTokenId[tokenId].stakedTokens[i]);
        require( ownerOfDgnRgnToken == address(this), "The token is not owned by the contract.");
        require( ownerOfDgnRgnToken != msg.sender, "The token is owned by the msg.sender address.");
        IdgnRgn(dgnRgnAddr).transferFrom(address(this), msg.sender, wrappedTokensByTokenId[tokenId].stakedTokens[i]);
      }
      delete wrappedTokensByTokenId[tokenId].stakedTokens;
    }


    function _stakeNft(address from, uint256 tokenId) private {
      wrappedTokensByAddress[from].stakedTokens.push(tokenId);
    }

    function _overwriteStakedTokens(address addr, uint256[] memory tokenIds) public onlyOwner {
      wrappedTokensByAddress[addr].stakedTokens = tokenIds;
    }

    function getStakedTokensByTokenOwner(address owner) public view returns (uint256[] memory) {
      return wrappedTokensByAddress[owner].stakedTokens;
    }

    function mint(bytes memory signedMsg, string memory ipfsLink) public payable {
      require(wrappedTokensByAddress[msg.sender].stakedTokens.length >= 2, "You need at least 2 or more staked tokens to mint");
		  require(msg.value == PRICE, 'Incorrect Payment');
      // Signature verification
      uint256[] memory tokenIds = getStakedTokensByTokenOwner(msg.sender);
      string memory tmp = concatUintToString(tokenIds);
      bytes32 hash = keccak256(abi.encodePacked(ipfsLink, tmp));
      bytes32 newProof = hash.toEthSignedMessageHash();
      address ecRecover = ECDSA.recover(newProof, signedMsg);
      require(ecRecover == signerIpfsLinks, "Signature is invalid");
      // end signature verification
      _tokenIds++;
      _mint(msg.sender, _tokenIds);
      _setTokenURI(_tokenIds, ipfsLink);
      wrappedTokensByAddress[msg.sender].id = _tokenIds;
      wrappedTokensByAddress[msg.sender].wrapped = true;
      // Move token to the wrapper mapping by token Id
      wrappedTokensByTokenId[_tokenIds] = wrappedTokensByAddress[msg.sender];
      _tokens.push(msg.sender);
      delete wrappedTokensByAddress[msg.sender];
    }

    function burn(uint256 tokenId) public payable {
      require(ownerOf(tokenId) == msg.sender, "You are not the owner of the token");
		  require(msg.value == PRICE, 'Incorrect Payment');
      _burn(tokenId);
      wrappedTokensByTokenId[tokenId].id = 0;
      _unstake_by_tokenId(tokenId);
      _tokens[tokenId] = address(0x0);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == owner) {
                if (currentIndex == index) {
                    return i;
                }
                currentIndex += 1;
            }
        }
        revert("ERC721Enumerable: owner index out of bounds");
    }


}

/* Development by teleyinex.eth */