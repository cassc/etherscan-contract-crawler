// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2020 adrianleb

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./BArt.sol";
import "./BStyle.sol";
import "./BFactory.sol";

contract BlockArtFactoryV2 is Ownable {
    using Strings for string;
    using SafeMath for uint256;

    event StyleAdded(uint256 indexed styleId);
    event StyleRemoved(uint256 indexed styleId);
    event StyleFeeCollected(
        address indexed to,
        uint256 styleId,
        uint256 amount
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event ReMint(address indexed to, uint256 indexed tokenId);
    event Burn(address indexed to, uint256 indexed tokenId);

    address public artsAddr; // art nft
    address public stylesAddr; // style nft
    address public oldFactoryAddr; // style nft
    uint256 public priceFloor; // minimum price for art nft mint
    uint256 public priceCeil; // max price for dutch auction for art nft mint
    uint256 public stylePrice; // fixed price for style nft mint
    uint256 public remintFee; // Cost of mutating a BlockArt metadata
    uint256 public burnFee; // Cost of burning a BlockArt
    uint256 public dutchLength; // length of dutch price decrease;
    uint256 public coinsBalance = 0; // fees collected for treasury

    mapping(uint256 => uint256) scfb; // style collectable fee balance
    mapping(uint256 => bool) asl; // allowed styles list

    struct Bp {
        uint256 bNumber;
        uint256 value;
    }

    constructor(
        address _artsAddr,
        address _stylesAddr,
        address _oldFactoryAddr
    ) {
        artsAddr = _artsAddr;
        stylesAddr = _stylesAddr;
        oldFactoryAddr = _oldFactoryAddr;
        priceFloor = 0.01 ether;
        priceCeil = 0.09 ether;
        stylePrice = 0.01 ether;
        remintFee = 0.01 ether;
        burnFee = 0.01 ether;
        dutchLength = 1028; // blocks
    }

    /// @dev check in the style allow list
    modifier onlyStyleListed(uint256 styleId) {
        require(isStyleListed(styleId), "Style not listed");
        _;
    }

    /// @dev check if sender owns token
    modifier onlyStyleOwner(uint256 styleId) {
        BlockStyle _style = BlockStyle(stylesAddr);
        require(msg.sender == _style.ownerOf(styleId), "Sender not Owner");
        _;
    }

    /// @dev check if sender owns token
    modifier onlyArtOwner(uint256 artId) {
        BlockArt _art = BlockArt(artsAddr);
        require(msg.sender == _art.ownerOf(artId), "Sender not Owner");
        _;
    }

    /// @dev Mint BlockArt NFTs, splits fees from value,
    /// @dev gives style highest between minimum/multiplier diff, and rest goes to treasury
    /// @param to The token receiver
    /// @param blockNumber The blocknumber associated
    /// @param styleId The style used
    /// @param metadata The tokenURI pointing to the metadata
    function mintArt(
        address to,
        uint256 blockNumber,
        uint256 styleId,
        string memory metadata
    ) external payable {
        uint256 price = calcArtPrice(blockNumber, styleId);
        bool canMint = canMintWithStyle(styleId);
        require(msg.value >= price, "Value too low");
        require(canMint, "Cannot mint style");

        BlockArt _blockArt = BlockArt(artsAddr);
        _blockArt.mint(to, blockNumber, styleId, msg.value, metadata);

        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        _oldFa.setPsfb(blockNumber, msg.value);

        BlockStyle _style = BlockStyle(stylesAddr);
        uint256 sfm = _style.getStyleFeeMul(styleId); // style fee multiplier
        uint256 msf = _style.getStyleFeeMin(styleId); // minimum style fee
        uint256 sf = msg.value.sub(msg.value.div(sfm).mul(100)); // style fee

        if (msf > sf) sf = msf; // whichever is higher
        scfb[styleId] = scfb[styleId].add(sf);
        coinsBalance = coinsBalance.add(msg.value.sub(sf));
    }

    /// @dev owner of BlockArts can change their token metadata URI for a fee
    function burnArt(uint256 tokenId) external payable onlyArtOwner(tokenId) {
        require(msg.value >= burnFee, "Value too low");
        BlockArt _ba = BlockArt(artsAddr);
        uint256 bav = _ba.tokenToValue(tokenId);
        uint256 bab = _ba.tokenToBlock(tokenId);
        uint256 _psfb = getPsfb(bab);
        _psfb = _psfb.sub(bav);

        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        _oldFa.setPsfb(bab, _psfb);

        _ba.burnToken(tokenId);
        coinsBalance = coinsBalance.add(msg.value);

        emit Burn(msg.sender, tokenId);
    }

    /// @dev owner of BlockArts can change their token metadata URI for a fee
    function remint(uint256 tokenId, string memory metadata)
        external
        payable
        onlyArtOwner(tokenId)
    {
        require(msg.value >= remintFee, "Value too low");
        BlockArt _blockArt = BlockArt(artsAddr);
        _blockArt.setTokenURI(tokenId, metadata);
        coinsBalance = coinsBalance.add(msg.value);
        emit ReMint(msg.sender, tokenId);
    }

    /// @dev Calculate the cost of minting a BlockArt NFT for a given block and style
    /// @dev Starts with the price floor
    /// @dev Checks for existing price for block, or does dutch auction
    /// @dev Applies style fee multiplier or minimum fee, whichever is highest
    /// @param blockNumber Block number selected
    /// @param styleId BlockStyle ID selected
    function calcArtPrice(uint256 blockNumber, uint256 styleId)
        public
        view
        returns (uint256)
    {
        BlockStyle _style = BlockStyle(stylesAddr);
        uint256 msf = _style.getStyleFeeMin(styleId);

        uint256 price = priceFloor;

        // check if there's a price set for this block
        uint256 _psfb = getPsfb(blockNumber);

        if (_psfb > 0) {
            // price floor for block set
            price = price.add(_psfb);
        } else {
            // go dutch
            if (blockNumber >= block.number) {
                price = price.add(priceCeil);
            } else if (blockNumber.add(dutchLength) >= block.number) {
                // only if blocknumber in dutch range from current block
                uint256 blockDiff = block.number - blockNumber;
                uint256 priceDiff = priceCeil.sub(
                    (blockDiff.mul(priceCeil.div(dutchLength)))
                );

                price = price.add(priceDiff);
            }
        }

        uint256 sfa = price.mul(_style.getStyleFeeMul(styleId)).div(100).sub(
            price
        ); //style fee amount

        if (sfa >= msf) {
            // style fee amount vs. minimum style fee
            return price.add(sfa);
        } else {
            return price.add(msf);
        }
    }

    /// @dev Mint BlockStyle NFTs, anyone can mint a BlockStyle NFT for a fee set by owner of contract
    /// @param to The token receiver
    /// @param cap Initial supply cap
    /// @param feeMul Initial Fee Multiplier
    /// @param feeMin Initial Minimum Fee
    /// @param canvas The token canvas URI
    function mintStyle(
        address to,
        uint256 cap,
        uint256 feeMul,
        uint256 feeMin,
        string memory canvas
    ) external payable {
        require(msg.value >= stylePrice, "Value too low");

        BlockStyle _blockStyle = BlockStyle(stylesAddr);
        _blockStyle.mint(to, cap, feeMul, feeMin, canvas);

        coinsBalance = coinsBalance.add(msg.value);
    }

    /// @dev Checks if is possible to mint with selected Style
    function canMintWithStyle(uint256 styleId)
        public
        view
        onlyStyleListed(styleId)
        returns (bool)
    {
        BlockStyle _style = BlockStyle(stylesAddr);
        BlockArt _art = BlockArt(artsAddr);

        // style supply cap
        uint256 ssc = _style.getStyleSupplyCap(styleId);

        // style current supply
        uint256 scs = _art.styleArtSupply(styleId);

        return scs < ssc;
    }

    /// @notice Withdrawals

    /// @dev BlockStyle owner collects style fees
    function collectStyleFees(uint256 styleId)
        external
        onlyStyleOwner(styleId)
    {
        uint256 _amount = scfb[styleId];

        scfb[styleId] = 0;
        payable(msg.sender).transfer(_amount);
        emit StyleFeeCollected(msg.sender, styleId, _amount);
    }

    /// @dev Contract Owner collects treasury fees
    function collectCoins() external onlyOwner {
        uint256 _amount = coinsBalance;

        coinsBalance = 0;
        payable(msg.sender).transfer(_amount);
    }

    /// @dev Contract Owner collects balance
    function collectBalance() external onlyOwner {
        uint256 _amount = address(this).balance;
        payable(msg.sender).transfer(_amount);
    }

    /// @notice Getters

    function getStyleBalance(uint256 styleId) external view returns (uint256) {
        return scfb[styleId];
    }

    function getCoinsBalance() external view returns (uint256) {
        return coinsBalance;
    }

    function getPriceCeil() external view returns (uint256) {
        return priceCeil;
    }

    function getPriceFloor() external view returns (uint256) {
        return priceFloor;
    }

    function getDutchLength() external view returns (uint256) {
        return dutchLength;
    }

    function getPsfb(uint256 blockNumber) public view returns (uint256) {
        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        return _oldFa.getPsfb(blockNumber);
    }

    /// @notice Internal Constants Management

    function setPsfb(uint256 blockNumber, uint256 value) public onlyOwner {
        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        _oldFa.setPsfb(blockNumber, value);
    }

    function setFloor(uint256 value) external onlyOwner {
        priceFloor = value;
    }

    function setCeil(uint256 value) external onlyOwner {
        priceCeil = value;
    }

    function setStylePrice(uint256 value) external onlyOwner {
        stylePrice = value;
    }

    function setDutchLength(uint256 value) external onlyOwner {
        dutchLength = value;
    }

    function setRemintFee(uint256 value) external onlyOwner {
        remintFee = value;
    }

    function setStyleBaseURI(string memory uri) external onlyOwner {
        BlockStyle _style = BlockStyle(stylesAddr);
        _style.setBase(uri);
    }

    function setArtContractURI(string memory uri) external onlyOwner {
        BlockArt _art = BlockArt(artsAddr);
        _art.setContractURI(uri);
    }

    /// @notice Allowed Styles List Management

    function addStyle(uint256 styleId) public onlyOwner {
        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        _oldFa.addStyle(styleId);
        emit StyleAdded(styleId);
    }

    function removeStyle(uint256 styleId) external onlyOwner {
        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        _oldFa.removeStyle(styleId);
        emit StyleRemoved(styleId);
    }

    function isStyleListed(uint256 styleId) public view returns (bool) {
        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        return _oldFa.isStyleListed(styleId);
    }

    function setPsfbs(Bp[] calldata psfba) external onlyOwner {
        for (uint256 i = 0; i < psfba.length; i++) {
            setPsfb(psfba[i].bNumber, psfba[i].value);
        }
    }

    function setAsl(uint256[] calldata asls) external onlyOwner {
        for (uint256 i = 0; i < asls.length; i++) {
            addStyle(asls[i]);
        }
    }

    function setOldFa(address _oldfa) external onlyOwner {
        oldFactoryAddr = _oldfa;
    }

    /// @dev transfers ownership of blockart and blockstyle token contracts owned by factory
    function transferTokensOwnership(address to) external onlyOwner {
        BlockStyle _style = BlockStyle(stylesAddr);
        BlockArt _art = BlockArt(artsAddr);
        _style.transferOwnership(to);
        _art.transferOwnership(to);
    }

    /// @dev transfers ownership of blockart and blockstyle token contracts owned by factory
    function transferOldFaOwnership(address to) external onlyOwner {
        BlockArtFactory _oldFa = BlockArtFactory(oldFactoryAddr);
        _oldFa.transferOwnership(to);
    }
}