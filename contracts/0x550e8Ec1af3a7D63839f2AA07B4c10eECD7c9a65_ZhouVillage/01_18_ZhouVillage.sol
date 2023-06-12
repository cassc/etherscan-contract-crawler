// Zhou Village developed by Froggy Labs

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWNXXNWWMMMMMMMMWWNXKKKKKKKKXNWWMMMMMMMMMWNXXKXXNWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWKOkkxdoooodxkkkkxdolllcccccccllodxkO00OkddddxxkkOOOO0NMMMMMMMMMMMM
// MMMMMMMMMMMMW0x0KkxO0Oko;',;:cllllllllllllllllcccc:;,,ck0K0kxddxO0xkNMMMMMMMMMMM
// MMMMMMMMMMMMXxOKxc;:clolccloolllllllllllllllllllllllc:codlc:::::oK0x0MMMMMMMMMMM
// MMMMMMMMMMMMKx00l::,,;clllolllllllllllllllllllllllllllc:,,,:::::l0KxOMMMMMMMMMMM
// MMMMMMMMMMMMKx0Ol;,;clolloolllllllllllllllllllllllllllllc:,,;:::o0KdOMMMMMMMMMMM
// MMMMMMMMMMMMNkOKo,;lollollllllllllllllllllllllllllllllllllc;,;:cxK0d0MMMMMMMMMMM
// MMMMMMMMMMMMWOkKo:lllooooolllllllllllllllloooolllllllllllclc;,;o0KkxXMMMMMMMMMMM
// MMMMMMMMMMMMMKxxlclodO00OxollolllllllllodkO000Oxollllllllcclc,:OK0dOMMMMMMMMMMMM
// MMMMMMMMMMMMMNx::llodxkkkdollllollllllldxxOOOkkdolllllllllccc::x0xkNMMMMMMMMMMMM
// MMMMMMMMMMMMMMk;:olllllloolloolollllllllllllollllllllllllllccc:cdkNMMMMMMMMMMMMM
// MMMMMMMMMMMMMMKlcollc;'.cxollolllllllllllc:;;ldllllllllllllccc:,oNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMXocoll:.  .:lllllllllllloc:,.  'locllllllllllcclc;dWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMM0lcoloc,.  .:lddxxxddolllc:'.   'clllllllllllllcc:lXMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWkclodxOkl,';ok0KKKK00Oxo:::;,',;:llllllllllllllccc:kWMMMMMMMMMMMMM
// MMMMMMMMMMMMW0lldx00xl;,cx0KKKKKKKKKK0d:,,;:dO0Oxolllllllllllccc:l0MMMMMMMMMMMMM
// MMMMMMMMMMMM0lcdOK0o;,:d0KK0dcccdOKKKK0xl:,',:xKK0xollllllllllccc:oXMMMMMMMMMMMM
// MMMMMMMMMMMM0cckKKd;,ckKXXX0l,''ckKKKKKK0kc,'';dKXKxolllllllllcc:,oXMMMMMMMMMMMM
// MMMMMMMMMMMMNd;oKKo,;xKXXKKK0OkO0K0KKKKKKKk:''';dKX0xlllllllclc::dXMMMMMMMMMMMMM
// MMMMMMMMMMMMMW0dk0o,;xKXXXK00000000KKKKKKKOc''''l0XKOollllllc:cd0WMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMN0kl,,l0XXXXKKKKKKKKKKKKKKKx:''',oKXXOdlllccclxKWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMNOo:;lOXXXKKKKKKKKKKKKKKOl,''':kXXKOoc:cox0NMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWXOl:odxkkO00KKKKKKOxoc,'',cxkkxoc::;cxXMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMNklclcccclllooooolc;,,,,,;clccccllllccl0WMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMXdcllllllloolllllllllllllllllllllllllllcckWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMNxcllllllllllllllllllllllllllllllllllllllcc0MMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMM0lllllllllllllllllllllllllllllllllllllllll:oXMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMNxclc:clllllllllllllllllllllllllcclllllllllccOMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMKlcl::lllllllllllllllllllllllllll::lllllllll:dWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMkcl:;clllllllllllllllllllllllllllc;cllllllll:oXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMNdcl;:llllllllllllllllllllllllllllc;:llllllllcc0MMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMXocc;clllllllllllllllllllllllllllll;:llllllllc:kMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMKlcc;clllllllllllllllllllllllllllll;:llllllllc:xWMMMMMMMMMMMMMMM

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

interface Ibark {
    function mint(address add, uint256 amount) external;
}

interface IErc20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ZhouVillage is ERC721AUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable, ERC2981Upgradeable {
    string public baseURI;
    string public contractURI;
    uint256 public rate;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public maxPertransaction;
    uint256 public decimals;
    bool public mintingStarted;

    Ibark public bark;

    struct Token {
        address addr;
        string name;
        uint256 price;
    }
    
    mapping(uint256 => Token) public tokens;
    uint256 public tokensCount;

    mapping(address => uint256) public mintedPerWallet;
    mapping(uint => mapping(address => uint)) private stakingClocks;

    function initialize() initializer initializerERC721A public {
        __ERC721A_init("Zhou Village", "ZHOU");
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __ERC2981_init();
        baseURI = "https://zhouvillage.mypinata.cloud/ipfs/QmPpEKcodPKHpdbkuq2vs9FzwYYFCJ73h9FSVcMaovJRqR/";
        contractURI = "https://zhouvillage.mypinata.cloud/ipfs/Qme5XewmSCfmhm8PExyG56trawZPK9FNQgTvmDLhEjSzYS";
        rate = 10;
        maxSupply = 3000;
        maxPerWallet = 3;
        maxPertransaction = 3;
        decimals = 10 ** 18;
        mintingStarted = false;
    }

    function mint(uint256 tokenIndex, uint256 amount) public payable {
        require(mintingStarted, "minting has not started");
        require( amount <= maxPertransaction, "exceeds max per transaction");
        require(totalSupply() + amount <= maxSupply, "zhou exceed max supply");
        require(mintedPerWallet[msg.sender] + amount <= maxPerWallet, "exceeded max per wallet");
        require(tokenIndex <= tokensCount, "token not supported");
        Token memory token = tokens[tokenIndex];
        IErc20 erc20 = IErc20(token.addr);
        uint256 mintPrice = decimals * token.price * amount;
        require(erc20.balanceOf(msg.sender) >= mintPrice, "Insufficient tokens for mint");
        erc20.transferFrom(msg.sender, address(this), mintPrice);
        uint256 tokenId = _nextTokenId();
        _mint(msg.sender, amount);
        mintedPerWallet[msg.sender] += amount;
        // begin staking
        for (uint256 i = tokenId; i < tokenId + amount; i++) {
            stakingClocks[i][msg.sender]=block.timestamp;
        }
    }

    function adminMint(address account, uint256 amount) public payable onlyOwner {
        _mint(account, amount);
    }

    function claim(uint256[] memory _tokenIds) public {
        require(balanceOf(msg.sender)>0, "Not Qualified For Reward");
        uint256[] memory tokenIds = new uint256[](_tokenIds.length);
        tokenIds = _tokenIds;

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (stakingClocks[tokenIds[i]][msg.sender] > 0) {
                current = block.timestamp - stakingClocks[tokenIds[i]][msg.sender];
                reward = ((rate * decimals) * current) / 86400;
                rewardbal += reward;
                stakingClocks[tokenIds[i]][msg.sender] = block.timestamp;
            }
        }
        bark.mint(msg.sender,rewardbal);
    }

    function checkBalance(uint256[] memory _tokenIds) public view returns (uint) {
        require(balanceOf(msg.sender)>0, "Not Qualified For Reward");
        uint256[] memory tokenIds = new uint256[](_tokenIds.length);
        tokenIds = _tokenIds;

        uint256 current;
        uint256 reward;
        uint256 rewardbal;
        for (uint256 i; i < tokenIds.length; i++) {
            if (stakingClocks[tokenIds[i]][msg.sender] > 0) {
                current = block.timestamp - stakingClocks[tokenIds[i]][msg.sender];
                reward = ((rate * decimals) * current) / 86400;
                rewardbal += reward;
            }
        }
        return rewardbal;
    }

    function checkStakingStartTime(uint256 tokenId, address account) public view returns (uint256) {
        return stakingClocks[tokenId][account];
    }

    function checkStakingStartTimes(uint256[] memory tokenIds, address account) public view returns (uint256[] memory) {
        uint256[] memory times = new uint256[](tokenIds.length);

        for (uint256 i; i< tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            times[i] = stakingClocks[tokenId][account];
        }

        return times;
    }

    function withdrawToken(address tokenContract, uint256 amount) public onlyOwner {
        IErc20 token = IErc20(tokenContract);
        token.transferFrom(address(this), msg.sender, amount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x701F7b4c1AF2DC54f6e2Cbba775228C3Fd0C80F9).transfer((balance / 100) * 90);
        payable(0x6b01aD68aB6F53128B7A6Fe7E199B31179A4629a).transfer((balance / 100) * 10);
    }

    function reserve(address wallet, uint256 pandas) public onlyOwner {
         require(totalSupply() + pandas <= maxSupply, "Max supply");
         _safeMint(wallet, pandas);
    }

    function setRoyaltyInfo(address reciever, uint96 _royaltyfee) external onlyOwner {
        _setDefaultRoyalty(reciever, _royaltyfee);
    }

    function setmaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setmaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        maxPertransaction = _maxPerTransaction;
    }

    function setMintingStarted(bool _mintingStarted) external onlyOwner {
        mintingStarted = _mintingStarted;
    }
  
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setcontractURI(string memory _contracturi) external onlyOwner {
        contractURI = _contracturi; 
    }

    function setRate(uint _rate) external onlyOwner {
        rate = _rate;
    }

    function setBarkAddress(address add) public onlyOwner {
        bark = Ibark(add);
    }

    function addMintToken(address tokenAddress, string memory tokenName, uint256 tokenPrice) public onlyOwner {
        tokensCount++;
        tokens[tokensCount] = Token(tokenAddress, tokenName, tokenPrice);
    }

    function setMintToken(uint256 tokenIndex, address tokenAddress, string memory tokenName, uint256 tokenPrice) public onlyOwner {
        require(tokenIndex <= tokensCount, "token not supported");
        tokens[tokenIndex] = Token(tokenAddress, tokenName, tokenPrice);
    }

    function getMintTokenDetails(uint256 tokenIndex) public view returns (Token memory) {
        return tokens[tokenIndex];
    }

    function getMintTokenAddress(uint256 tokenIndex) public view returns (address) {
        return tokens[tokenIndex].addr;
    }

    function getMintTokenName(uint256 tokenIndex) public view returns (string memory) {
        return tokens[tokenIndex].name;
    }

    function getMintTokenPrice(uint256 tokenIndex) public view returns (uint256) {
        return tokens[tokenIndex].price;
    }

    // =============================================================
    //                      ERC2981 OVERRIDES
    // =============================================================

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
        stakingClocks[tokenId][to]=block.timestamp;
        stakingClocks[tokenId][from]=0;
    }
       
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
        stakingClocks[tokenId][to]=block.timestamp;
        stakingClocks[tokenId][from]=0;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
        stakingClocks[tokenId][to]=block.timestamp;
        stakingClocks[tokenId][from]=0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981Upgradeable,ERC721AUpgradeable) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721. 
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC2981Upgradeable).interfaceId;
    }
}