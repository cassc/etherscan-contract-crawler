// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./contracts/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./contracts/CimoStaking.sol";


contract Cinnamoons is ERC721Enumerable, Ownable, DefaultOperatorFilterer, AccessControl {
    using Strings for uint256;

    string _baseTokenURI = ""; // base URI (used by NFT market places)
    uint256 private _price = 0.05 ether; // price of NFT
    bool public _paused = true; // if true, minting is paused (update it via pause function
    IERC20 private _cimo; // the contract
    CimoStaking private _staking;
    uint256 public _maxNFTAmount = 20; // maximum amount of NFTs per wallet
    uint256 public _maxSupply = 3000; //maximum supply of NFTs

    // withdraw addresses
    address marketingAddress = 0x98acBAec797415754e251BEa178B53879510dc3E;

    // canWithdraw modifier checks if NFT contract has ETH
    modifier canWithdraw() {
        require(address(this).balance > 0 ether);
        _;
    }

    //
    struct MarketingAddresses {
        address payable addr;
        uint256 percent;
    }

    MarketingAddresses[] marketingAddresses;

    constructor() ERC721("Cinnamoons", "Cinnamoons") {
        marketingAddresses.push(
            MarketingAddresses(payable(address(marketingAddress)), 100)
        );
        _cimo = IERC20(0xC3f65b1c45B0D42a472CD0Fbd37dD6678AEf667a);
        _staking = CimoStaking(0xFdffB4Fd1FD55d40Cb27EDFae02f752fCd50Fd56);

        for(uint i; i < _maxNFTAmount; i++){
            _safeMint(marketingAddress, i);
        }
    }

    /**
     * @dev Public function to mint NFTs.
     * @param num uint256 number of NFTs user wants to mint
     * payable function means you need to send ETH when calling function. ETH amount should be num * price
     */

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply(); //get current supply - e.g. total number of minted NFTs

        require(!_paused, "Minting paused"); //check if minting is pause.
        require(
            num <= _maxNFTAmount,
            "You can mint a maximum of 20 Cinnamoons at the time"
        ); // check if desired number exceeds max NFT amount
        require(supply + num <= _maxSupply, "Exceeds maximum Cinnamoons supply"); // check if current supply exceeds max supply
        require(
            ERC721.balanceOf(msg.sender) + num <= _maxNFTAmount,
            "Exceeds maximum NFTs per wallet"
        );
        require(msg.value >= getDiscountedPrice(num), "Ether sent is not correct"); // check if user sent enough ETH to mint NFTs

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i); // mint num NFTs
        }
    }

    /**
     * @dev Public view to check users NFTs.
     * @param _owner address - address of user
     * returns the array of NFT IDs
     */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**
     * @dev Public function to change price of NFT.
     * @param _newPrice uint256 - new price (use wei, e.g - 0.1 ETH = 100000000000000000)
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    /**
     * @dev Public view returns base URI. Used for fetching the metadata of each NFT
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Public function to change baseURI.
     * @param baseURI string - new baseURI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Public view returns current price per NFT
     */
    function getPrice() public view returns (uint256) {
        return _price;
    }


    /**
     * @dev Public function to pause/unpause minting.
     * @param val bool - new status. true if pause, false if unpaused
     */
    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    /**
    * @dev Public view returns staking bonus points for certain tokenId
    */
    function getDiscountedPrice(uint256 num) public view returns (uint256) {
        
        (,,,, uint112 weightedBalance,,,) = _staking.userInfo(1, msg.sender);
        (,,,, uint112 weightedLPBalance,,,) = _staking.userInfo(0, msg.sender);

        // we fixate Cimo lp reserves to 2M to avoid fluctuation during the price action
        // 5955695730758912164 is total suppply based on block 16168591
        uint256 lpCimo = uint256(weightedLPBalance) * 2e16 / 5955695730758912164;  

        uint256 bal = _cimo.balanceOf(msg.sender) + uint256(weightedBalance) + lpCimo;

        if(bal >= 10000000 * 1e9 && bal < 25000000 * 1e9){
            return _price * num * 90 / 100;
        } else if (bal >= 25000000 * 1e9 && bal < 50000000 * 1e9){
            return _price * num * 75 / 100;
        } else if (bal >= 50000000 * 1e9) {
            return _price * num * 50 / 100;
        }

        return _price * num;
    }

    // Withdraw ETH from NFT contract
    function withdraw() external payable onlyOwner canWithdraw {
        uint256 nbalance = address(this).balance;
        for (uint256 i = 0; i < marketingAddresses.length; i++) {
            MarketingAddresses storage m = marketingAddresses[i];
            payable(m.addr).call{value: (nbalance * m.percent) / 100} ("");
            //m.addr.transfer((nbalance * m.percent) / 100);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override (ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}