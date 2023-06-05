// SPDX-License-Identifier: MIT
// Galaxy Heroes NFT game 
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Modifiers1155 is ERC1155Supply, Ownable {

    using Strings for uint256;

    struct Partners {
        uint256 limit;
        uint256 nftMinted;
    }
    struct TokenReq {
        uint256 mintPrice;
        uint256 maxBuyPerTx;
        uint256 maxMintPerTx;
        uint256 stopMintAfter;
        uint256 maxTotalSupply;
        uint256 reservedForPartners;
    }

    string public name = "SIDUS NFT HEROES - Galaxy Modificators";

    mapping(uint256 => TokenReq) public tokenReq;
    mapping(address => mapping(uint256 => Partners)) public partnersLimit;
    mapping(address => mapping(uint256 => uint256)) public tokensForMint;

    //Event for track mint channel:
    // 2 - With Ethere
    // 3 - Partners White List
    // 4 - With ERC20
    event MintSource(uint256 tokenId, uint256 amount,  uint8 channel);
    event PartnesChanged(uint256 tokenId, address partner, uint256 limit);

    constructor()
       ERC1155("")  {
    }


    function multiMint(uint256 tokenID) external payable {
        require(totalSupply(tokenID) > 0, "Only minted NFT") ;
        uint256 mintAmount = _availableFreeMint(msg.sender, tokenID);
        if(mintAmount > 0) {
            require(msg.value == 0, "No need Ether");
            mintAmount = _checkMintAmount(tokenID, mintAmount, true);
            _multiMint(msg.sender, mintAmount, tokenID, 3);
            partnersLimit[msg.sender][tokenID].nftMinted += mintAmount;
            tokenReq[tokenID].reservedForPartners -= mintAmount;
        }else {
            require(msg.value >= tokenReq[tokenID].mintPrice, "Less ether for mint");
            uint256 estimateAmountForMint = msg.value / tokenReq[tokenID].mintPrice;
            require(estimateAmountForMint <= tokenReq[tokenID].maxBuyPerTx, "So much payable mint");
            require(tokenReq[tokenID].stopMintAfter > tokenReq[tokenID].reservedForPartners, "Minting is paused");
            require(tokenReq[tokenID].stopMintAfter - tokenReq[tokenID].reservedForPartners >= totalSupply(tokenID) + estimateAmountForMint, "Minting is paused");
            _multiMint(msg.sender, estimateAmountForMint, tokenID, 2);
            if ((msg.value - estimateAmountForMint * tokenReq[tokenID].mintPrice) > 0) {
                address payable s = payable(msg.sender);
                s.transfer(msg.value - estimateAmountForMint * tokenReq[tokenID].mintPrice);
            }
        }
    }


    function mintWithERC20(address _withToken, uint256 _tokenID, uint256 _nftAmountForMint) external {
        require(totalSupply(_tokenID) > 0, "Only minted NFT") ;
        require(tokensForMint[_withToken][_tokenID]> 0, "No mint with this token");
        require(_nftAmountForMint <= tokenReq[_tokenID].maxBuyPerTx, "So much payable mint");
        require(tokenReq[_tokenID].stopMintAfter > tokenReq[_tokenID].reservedForPartners, "Minting is paused");
        require(tokenReq[_tokenID].stopMintAfter - tokenReq[_tokenID].reservedForPartners >= totalSupply(_tokenID) + _nftAmountForMint, "Minting is paused");
        IERC20(_withToken).transferFrom(
            msg.sender,
            address(this),
            tokensForMint[_withToken][_tokenID] * _nftAmountForMint
        );
        _multiMint(msg.sender, _nftAmountForMint, _tokenID, 4);
    }

    // function burn(address account, uint256 _tokenID, uint256 amount) external {
    //     require(account == msg.sender || isApprovedForAll(account, msg.sender),
    //     "ERC1155: caller is not owner nor approved");
    //     _burn(account, _tokenID, amount);

    // }

    function availableFreeMint(address _partner, uint256 _tokenID) external view returns (uint256) {
        return _availableFreeMint(_partner, _tokenID);
    }

    function getMintPrice(uint256 id) external  view returns (uint256) {
         return tokenReq[id].mintPrice;
    }

    function getTokenDetails(uint256 _id) external view returns (TokenReq memory) {
        return tokenReq[_id];
    }
//    function checkMintAmount(uint256 _tokenID, uint256 _amount, bool isFree) external view returns (uint256) {
//        return _checkMintAmount(_tokenID, _amount, isFree);
//    }




    ///////////////////////////////////////////////////////////////////
    /////  Owners Functions ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    function setPartner(address _partner, uint256 _tokenID, uint256 _limit) external onlyOwner {
        _setPartner(_tokenID, _partner, _limit);
    }

    function setPartnerBatch(uint256 _tokenID,  address[] memory _partners, uint256[] memory _limits) external onlyOwner {
        require(_partners.length == _limits.length, "Array params must have equal length");
        require(_partners.length <= 256, "Not more than 256");
        for (uint8 i; i < _partners.length; i ++) {
            _setPartner(_tokenID, _partners[i], _limits[i]);
        }
    }



    function setMintPrice(uint256 id, uint256 _newPrice) external onlyOwner {
        tokenReq[id].mintPrice = _newPrice;
    }

    function setMaxTotalSupply(uint256 id, uint256 _maxSupply) external onlyOwner {
        tokenReq[id].maxTotalSupply = _maxSupply;
    }

    function setStopMinterAfter(uint256 id, uint256 _stopMinter) external onlyOwner {
        tokenReq[id].stopMintAfter = _stopMinter;
    }

    function setPriceInToken(address _token, uint256 _tokenId, uint256 _pricePerMint) external onlyOwner {
        require(_token != address(0), "No zero");
        tokensForMint[_token][_tokenId] = _pricePerMint;
    }

    function withdrawEther() external onlyOwner {
        address payable o = payable(msg.sender);
        o.transfer(address(this).balance);
    }

    function withdrawTokens(address _erc20) external onlyOwner {
        IERC20(_erc20).transfer(msg.sender, IERC20(_erc20).balanceOf(address(this)));
    }


    function createNew(
        address account,
        uint256 id,
        uint256 amount,
        uint256 _mintPrice,
        uint256 _maxBuyPerTx,
        uint256 _maxMintPerTx,
        uint256 _stopMintAfter,
        uint256 _maxTotalSupply) external onlyOwner {
        _mint(account, id, amount, bytes('0'));
        _setTokenReq(id, _mintPrice,_maxBuyPerTx, _maxMintPerTx, _stopMintAfter, _maxTotalSupply);
    }

    function createNewBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory _mintPrice,
        uint256[] memory _maxBuyPerTx,
        uint256[] memory _maxMintPerTx,
        uint256[] memory _stopMintAfter,
        uint256[] memory _maxTotalSupply) external onlyOwner {
        require(ids.length == _mintPrice.length, "mintPrice params must have equal length");
        require(ids.length == _maxBuyPerTx.length, "maxBuyPerTx params must have equal length");
        require(ids.length == _maxMintPerTx.length, "maxMintPerTx params must have equal length");
        require(ids.length == _stopMintAfter.length, "stopMintAfter params must have equal length");
        require(ids.length == _maxTotalSupply.length, "maxTotalSupply params must have equal length");
        _mintBatch(account, ids, amounts, bytes('0'));

        for(uint256 i=0; i<ids.length; i++) {
            _setTokenReq(ids[i], _mintPrice[i],_maxBuyPerTx[i], _maxMintPerTx[i], _stopMintAfter[i], _maxTotalSupply[i]);
        }

    }

    function editTokenReq(
        uint256 id,
        uint256 _mintPrice,
        uint256 _maxBuyPerTx,
        uint256 _maxMintPerTx,
        uint256 _stopMintAfter,
        uint256 _maxTotalSupply
    ) external onlyOwner {
        _editTokenReq(id, _mintPrice,_maxBuyPerTx, _maxMintPerTx, _stopMintAfter, _maxTotalSupply);
    }

    ///////////////////////////////////////////////////////////////////
    /////  INTERNALS      /////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    function _availableFreeMint(address _partner, uint256 _tokenID) internal view returns (uint256) {
        return partnersLimit[_partner][_tokenID].limit - partnersLimit[_partner][_tokenID].nftMinted;
    }

    /// function SET new limit, NOT INCREMENT or DECREMENT
    function _setPartner(uint256 _tokenID, address _partner, uint256 _limit) internal {
        require(_partner != address(0), "No zero");
        require(_limit  >= partnersLimit[_partner][_tokenID].nftMinted, "Cant decrease more then minted");
        if (partnersLimit[_partner][_tokenID].limit < _limit) {
            tokenReq[_tokenID].reservedForPartners += (_limit - partnersLimit[_partner][_tokenID].limit);
        } else {
             tokenReq[_tokenID].reservedForPartners -= (partnersLimit[_partner][_tokenID].limit - _limit);
        }
        partnersLimit[_partner][_tokenID].limit = _limit;
        emit PartnesChanged(_tokenID, _partner, _limit);
    }

    function _setTokenReq(
        uint256 _id, 
        uint256 _mintPrice, 
        uint256 _maxBuyPerTx, 
        uint256 _maxMintPerTx, 
        uint256 _stopMintAfter, 
        uint256 _maxTotalSupply
    ) internal {
        tokenReq[_id] = TokenReq({
            mintPrice: _mintPrice,
            maxBuyPerTx: _maxBuyPerTx,
            maxMintPerTx: _maxMintPerTx,
            stopMintAfter: _stopMintAfter,
            maxTotalSupply: _maxTotalSupply,
            reservedForPartners: 0
            });
    }

    function _editTokenReq(
        uint256 _id, 
        uint256 _mintPrice, 
        uint256 _maxBuyPerTx, 
        uint256 _maxMintPerTx, 
        uint256 _stopMintAfter, 
        uint256 _maxTotalSupply
    ) internal {
            tokenReq[_id].mintPrice      = _mintPrice;
            tokenReq[_id].maxBuyPerTx    = _maxBuyPerTx;
            tokenReq[_id].maxMintPerTx   = _maxMintPerTx;
            tokenReq[_id].stopMintAfter  = _stopMintAfter;
            tokenReq[_id].maxTotalSupply = _maxTotalSupply;
    }


    function _multiMint(address to, uint256 amount, uint256 tokenID, uint8 channel) internal  {
        require(totalSupply(tokenID) + tokenReq[tokenID].reservedForPartners + amount <= tokenReq[tokenID].maxTotalSupply, "No more this tokens");
        _mint(to, tokenID, amount, bytes('0'));
        emit MintSource(tokenID, amount, channel);
    }

    function _checkMintAmount(uint256 _tokenID, uint256 _amount, bool isFree) internal view returns (uint256) {
        if(isFree) {
            return _amount > tokenReq[_tokenID].maxMintPerTx ? tokenReq[_tokenID].maxMintPerTx : _amount;
        }else {
            return _amount > tokenReq[_tokenID].maxBuyPerTx ? tokenReq[_tokenID].maxBuyPerTx : _amount;
        }
    }

    function uri(uint256 _tokenID) public view virtual override returns (string memory) {
        return string(abi.encodePacked(
            "https://nftstars.app/backend/api/v1/nfts/metadata/0x",
            toAsciiString(address(this)),
            "/", _tokenID.toString())
        );
    }

        function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
     }

}