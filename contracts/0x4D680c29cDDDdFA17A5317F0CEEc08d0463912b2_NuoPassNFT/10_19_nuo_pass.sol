// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "./interface/INuoPass.sol";

import "./nuo_merkle.sol";
import "./season_sale.sol";

contract NuoPassNFT is ERC721AQueryable, DefaultOperatorFilterer, SeasonSale, NuoMerkle, ReentrancyGuard, INuoPass {
    constructor() ERC721A("NuoChip", "NuoChip") {
        BASE_URI = "https://nuo_api.nuo2069.io/api/v1/metadata/";
        updateSeasonConfig(1,1,1,69,1,0,1,2);
        updateSeasonConfig(1,2,2,1000,2,29000000000000000,1,2);
        updateSeasonConfig(1,3,3,1000,1,29000000000000000,1,0);
        updateSeasonConfig(1,4,0,0,2,39000000000000000,1,0);
    }

    bool public paused = true;
    string public BASE_URI;
    address public nuoNFTAddress;

    function initialize() public onlyOwner {
        // todo initialize contract params
    }

    function setBaseUri(string memory uri) public onlyOwner {
        BASE_URI = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setNuoNFT(address _NuoNFTAddress) public onlyOwner {
        require(_NuoNFTAddress != address(0), "NuoNFT can not be address(0)!");
        nuoNFTAddress = _NuoNFTAddress;
    }

    modifier notPaused() {
        require(!paused, "sale paused");
        _;
    }

    /**
     * @notice  set the merkleTree
     * @dev     .
     * @param   _treeId  merkleTre map id
     * @param  _root merkleTree root
     */
    function setMerkleTree(uint256 _treeId, bytes32 _root) public onlyOwner {
        merkleRoots[_treeId] = _root;
    }

    /**
     * @notice  freeMint using merkleproof
     * @dev     .
     * @param   _season  mint season
     * @param   _round  mint round
     * @param   index  merkle index
     * @param   account  merkle account
     * @param   amount  merkle amount
     * @param   merkleProof  merkle proof
     */
    function freeMint(
        uint32 _season,
        uint32 _round,
        uint256 _mintAmount,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public notPaused nonReentrant {
        address wallet = _msgSender();
        // 1. check if freeMint is begining
        require(account == wallet, "you are not the one!");

        // 2. get config data
        SeasonData storage r = _seasonDataMap[_season][_round];

        // 3. check if freeMint is begining
        require(r.status == SaleStatus.Saling, "sale not started or finished");

        // 4. check pay value, due to free, passed
        require(r.price == 0, "this round is not free mint!");

        // 5. check minted count reached cap
        require(r.maxSupply >= r.minted + _mintAmount, "mint reached round cap");

        // 6. check user mint count reached cap
        uint256 userRoundMinted = getUserMintedCount(_season, _round, wallet);
        require(r.userMaxMint >= userRoundMinted + _mintAmount, "mint reached user cap");

        // 7. verify merkle proof
        bool claimed = merkleVerifyAndSetClaimed(r.treeId, index, account, amount, merkleProof);

        // if not claimed, claim and charge to the pool
        if (!claimed) {
            addCharge(_season, _round, wallet, amount);
        }
        // check if charged amount can cover the mintAmount
        require(getCharged(_season, _round, wallet) >= _mintAmount, "amount out of range!");

        // 8. mint
        _safeMint(wallet, _mintAmount);

        // 9. update total progress
        r.minted += _mintAmount;
        // 10. update user progress
        addUserMinted(_season, _round, account, _mintAmount);
        // 11. cosume the charged amount
        cosumeCharge(_season, _round, account, _mintAmount);
    }

    /**
     * @notice  whiteList mint using merkleproof
     * @dev     .
     * @param   _season  mint season
     * @param   _round  mint round
     * @param   _mintAmount the actual mint amount
     * @param   index  merkle index
     * @param   account  merkle account
     * @param   amount  merkle amount
     * @param   merkleProof  merkle proof
     */
    function whitelistMint(
        uint32 _season,
        uint32 _round,
        uint256 _mintAmount,
        uint index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public payable notPaused nonReentrant {
        address wallet = _msgSender();
        // 1. check if freeMint is begining
        require(account == wallet, "you are not the one!");

        // 2. get config data
        SeasonData storage r = _seasonDataMap[_season][_round];

        // 3. check if freeMint is begining
        require(r.status == SaleStatus.Saling, "sale not started or finished");

        // 4. check pay value, due to free, passed
        require(r.price * _mintAmount <= msg.value, "param error, season or round price is not free");

        // 5. check minted count reached cap
        require(r.maxSupply >= r.minted + _mintAmount, "mint reached round cap");

        // 6. check user mint count reached cap
        uint256 userRoundMinted = getUserMintedCount(_season, _round, wallet);
        require(r.userMaxMint >= userRoundMinted + _mintAmount, "mint reached user cap");

        // 7. verify merkle proof
        bool claimed = merkleVerifyAndSetClaimed(r.treeId, index, account, amount, merkleProof);
        // if not claimed, claim and charge to the pool
        if (!claimed) {
            addCharge(_season, _round, wallet, amount);
        }
        // check if charged amount can cover the mintAmount
        require(getCharged(_season, _round, wallet) >= _mintAmount, "amount out of range!");

        // 8. mint
        _safeMint(wallet, _mintAmount);

        // 9. update total progress
        r.minted += _mintAmount;
        // 10. update user progress
        addUserMinted(_season, _round, account, _mintAmount);
        // 11. cosume the charged amount
        cosumeCharge(_season, _round, account, _mintAmount);
    }

    /**
     * @notice  .
     * @dev     .
     * @param   _season the public mint season
     * @param   _round  the public mint round
     * @param   amount  the amount of user mint
     */
    function publicMint(
        uint32 _season,
        uint32 _round,
        uint256 amount
    ) public payable notPaused nonReentrant {
        address wallet = _msgSender();
        require(msg.sender == tx.origin,'eoa only');
        // 1. get config data
        SeasonData storage r = _seasonDataMap[_season][_round];

        // 2. check if freeMint is begining
        require(r.status == SaleStatus.Saling, "sale not started or finished");

        // 3. check pay value, due to free, passed
        require(r.price * amount <= msg.value, "param error, season or round price is not free");

        // 4. check minted count reached cap
        require(r.maxSupply >= r.minted + amount, "mint reached cap");

        // 5. check user mint count reached cap
        uint256 userRoundMinted = getUserMintedCount(_season, _round, wallet);
        require(r.userMaxMint >= userRoundMinted + amount, "mint reached cap");

        // 6. check if use proof check
        require(r.treeId == 0, "this round mint needs list!");

        // mint
        _safeMint(wallet, amount);

        // 9. update total progress
        r.minted += amount;

        // 10. update user progress
        addUserMinted(_season, _round, wallet, amount);
    }

    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function burn(uint256 tokenId, address _user) external override {
        require(_msgSender() == owner() || _msgSender() == nuoNFTAddress, "U shall not pass");
        require(ownerOf(tokenId) == _user, "only owner can burn this token!");
        _burn(tokenId);
    }

    bool public operatorFilteringEnabled = true;

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC721A) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        return ERC721A.supportsInterface(interfaceId);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function bulkGetRoundStatus(uint32 _season,uint32[] calldata roundList) public view returns (bool[] memory result){
        uint256 len = roundList.length;
        result = new bool[](len);
        for(uint8 i = 0; i < len; i++ ){
            uint32 _round = roundList[i];
            if(paused) {
                result[i] = false;
            } else {
                SeasonData storage r = _seasonDataMap[_season][_round];
                result[i] = r.status == SaleStatus.Saling;
            }
        }
        return result;
    }
}