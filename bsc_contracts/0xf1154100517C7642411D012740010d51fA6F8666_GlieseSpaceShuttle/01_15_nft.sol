// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract GlieseSpaceShuttle is ERC721Enumerable, Ownable {
    using Strings for uint256;

    struct UserInfo {
        uint rewardDebt;
        uint realizedReward;
    }

    string public baseURI = "ipfs://QmQr9oDTPevE1VfbvpvtSn5EzPLFW5umpmJpGArhLVQaQi/";
    string public baseExtension = ".json";

    address public constant usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public receiptWallet = 0x57150002d6c7d54932277ecCEdc31725d63c1000;

    uint public totalRewards;
    uint public accRewardPerShare;
    uint public mineFee = 1e18;
    uint public maxSupply = 999;
    mapping (address => UserInfo) public userInfo;
    mapping (address => bool) public isValidCaller;
    mapping (address => bool) public isBlclist;// for usdt dividend
    mapping (address => bool) public isWhitelist;// for mint
    mapping (address => bool) public hasMinted;
    bool public privateSale = true;

    constructor() ERC721("Gliese Space Shuttle", "GlieseSpaceShuttle") {}

    receive() external payable {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrivateSale(bool _privateSale) public onlyOwner {
        privateSale = _privateSale;
    }

    function setMineFee(uint newMintFee) public onlyOwner {
        mineFee = newMintFee;
    }

    function setMultipleWhitelist(address[] calldata accounts, bool _isWhitelist) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            isWhitelist[accounts[i]] = _isWhitelist;
        }
    }

    function setMaxSupply(uint newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setReceiptWallet(address _receiptWallet) public onlyOwner {
        receiptWallet = _receiptWallet;
    }

    function setBlclist(address account, bool flag) public onlyOwner {
        isBlclist[account] = flag;
    }

    function setValidCaller(address caller, bool flag) public onlyOwner {
        require(caller.code.length > 0, "calller is not a contract");
        isValidCaller[caller] = flag;
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function mint() external payable {
        if (privateSale) {
            require(isWhitelist[msg.sender], "you are not in whitelist");
        }
        require(!hasMinted[msg.sender], "already minted");
        require(msg.value >= mineFee, "unsufficient mint fee");
        payable(receiptWallet).transfer(msg.value);

        uint newTokenId = totalSupply();
        require(newTokenId < maxSupply, "exceed max supply");
        _safeMint(msg.sender, newTokenId);
        hasMinted[msg.sender] = true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) return;
        uint pendingRewards = withdrawableReward(from);
        if (pendingRewards > 0) {
            require(IERC20(usdt).balanceOf(address(this)) >= pendingRewards, "unsufficient balances");
            IERC20(usdt).transfer(from, pendingRewards);
            delete userInfo[from];
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        if (to == address(0)) return;

        require(balanceOf(to) <= 1, "max one amount for per account");

        UserInfo storage ui = userInfo[to];
        ui.rewardDebt = accRewardPerShare;
    }

    function distribute(uint amount) external returns (bool) {
        require(isValidCaller[msg.sender], "not valid caller");
        if (totalSupply() == 0) {
            return false;
        }
        totalRewards += amount;
        accRewardPerShare += amount / totalSupply();
        return true;
    }

    function withdrawableReward(address account) public view returns (uint) {
        if (isBlclist[account]) return 0;
        UserInfo storage ui = userInfo[account];
        if (balanceOf(account) > 0) {
            return accRewardPerShare - ui.realizedReward - ui.rewardDebt;
        } else {
            return 0;
        }
    }

    function withdrawReward() public {
        uint reward = withdrawableReward(msg.sender);
        if (reward <= 0) return;
        require(IERC20(usdt).balanceOf(address(this)) >= reward, "unsufficient balances");

        UserInfo storage ui = userInfo[msg.sender];
        IERC20(usdt).transfer(msg.sender, reward);
        ui.realizedReward += reward;

    }

    function viewAmountOfThis(address _token) external view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    function exactLeftTokens(address _token, uint amount) external onlyOwner {
        uint balanceOfThis = IERC20(_token).balanceOf(address(this));
        require(balanceOfThis >= amount, 'unsufficient balance');
        IERC20(_token).transfer(msg.sender, amount);
    }

    function exactBNBOfThis() external onlyOwner {
        uint balanceOfThis = address(this).balance;
        payable(msg.sender).transfer(balanceOfThis);
    }
}