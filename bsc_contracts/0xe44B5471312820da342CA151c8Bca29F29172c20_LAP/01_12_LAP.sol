/***
* MIT License
* ===========
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
 __         __     ______   ______     ______   ______     ______     __    __    
/\ \       /\ \   /\  ___\ /\  ___\   /\  ___\ /\  __ \   /\  == \   /\ "-./  \   
\ \ \____  \ \ \  \ \  __\ \ \  __\   \ \  __\ \ \ \/\ \  \ \  __<   \ \ \-./\ \  
 \ \_____\  \ \_\  \ \_\    \ \_____\  \ \_\    \ \_____\  \ \_\ \_\  \ \_\ \ \_\ 
  \/_____/   \/_/   \/_/     \/_____/   \/_/     \/_____/   \/_/ /_/   \/_/  \/_/ 
                                                                                  
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/ERC721A.sol";

contract LAP is ERC721A, Ownable  {
  using Strings for uint256;
  string  public _base;
  string  public _metatype;
  uint256 public lastTokenId;
  mapping (address => bool) public _minters;

  constructor(string memory name,string memory symbol,string memory base, string memory metatype) 
  ERC721A(name, symbol) {
      _base = base;
      _metatype = metatype;
      _minters[msg.sender] = true;
  }

  function _baseURI() internal view override returns (string memory) {
      return _base;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return bytes(_base).length > 0 ? string(abi.encodePacked(_base, symbol(), _metatype)) : "";
  }
    
  function listMyNFT(address owner) external view returns (uint256[] memory tokens) {
        uint256 owned = balanceOf(owner);
        tokens = new uint256[](owned);
        uint256 start = 0;
        for (uint i=0; i<totalSupply(); i++) {
            if (ownerOf(i) == owner) {
                tokens[start] = i;
                start ++;
            }
        }
    }

  function airdrop(address[] calldata whiteList) external {

      require(_minters[msg.sender], "!minter");

      for (uint i=0; i<whiteList.length; i++) {
            address to = whiteList[i];
            require(to != address(0),"Address is not valid");

            //for 721 A
            _safeMint(to, 1);
            //for 721 normal
            // _safeMint(to, lastTokenId+i+1);
      }
      lastTokenId = lastTokenId+whiteList.length;
  }

  function setURIPrefix(string memory base) public onlyOwner{
      _base = base;
  }

  function setMetaType(string memory metatype) public onlyOwner{
      _metatype = metatype;
  }

  function addMinter(address minter) public onlyOwner 
  {
      _minters[minter] = true;
  }
  
  function removeMinter(address minter) public onlyOwner 
  {
      _minters[minter] = false;
  }
}