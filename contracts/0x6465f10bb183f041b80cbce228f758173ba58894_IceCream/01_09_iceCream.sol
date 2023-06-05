// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBurnAndAirdropContract {
    function airdrop(address receipt, uint256 quantity) external;
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @title Ice Cream NFT Contract
/// @author 0xAnduin
contract IceCream is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // Constructor
    constructor() ERC721A("ICE CREAM", "ice cream") {}

    // Constant
    uint256 public constant MAX_SUPPLY = 1888;
    uint256 public constant MAX_PER_WALLET = 5;

    // Tokenization
    string public baseURI = "ipfs://QmRiRyHMTvRv92Wab3yn7bMaMekAhjK1sEbyFofioUn94Q/";

    // Contract control
    bool public mintEnable = false;
    bool public stakingEnable = false;
    bool public burnAndMintEnable = false;

    // Storage
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256[]) public ownedTokens;
    mapping(uint256 => uint256) public lastClaimedScoreAt;
    mapping(address => uint256) public totalScoreOf;

    // Modifier
    modifier callerIsUser() {
        require(_msgSender() == tx.origin, "No Contract Please");
        _;
    }

    // Function    
    function devMint(uint256 quantity) external onlyOwner nonReentrant {
        require(quantity + totalSupply() <= MAX_SUPPLY, "Exceed Max Supply");
        _safeMint(_msgSender(), quantity);
    }

    function mint(uint256 quantity) external callerIsUser nonReentrant {
        require(mintEnable, "Mint Not Enabled");
        require(
            quantity + _numberMinted(_msgSender()) <= MAX_PER_WALLET,
            "Exceed Max Per Wallet"
        );
        if (quantity + totalSupply() > MAX_SUPPLY) {
            quantity = MAX_SUPPLY - totalSupply();
        }
        require(quantity != 0, "Sold Out");
        _safeMint(_msgSender(), quantity);
    }

    function staking(uint256[] memory tokenIds) external nonReentrant {
        require(stakingEnable, "Staking Not Enabled");
        require(tokenIds.length > 0, "Empty TokenIds Array");
        claimScore();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            transferFrom(_msgSender(), address(this), tokenId);
            lastClaimedScoreAt[tokenId] = block.timestamp;
            tokenOwner[tokenId] = _msgSender();
            ownedTokens[_msgSender()].push(tokenId);
        }
    }

    function stakingTokenWithdraw(
        uint256[] memory tokenIds
    ) external nonReentrant {
        require(tokenIds.length > 0, "Empty TokenIds Array");
        claimScore();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenOwner[tokenId] == _msgSender(), "Not Token Owner");
            IERC721 token = IERC721(address(this));
            token.transferFrom(address(this), _msgSender(), tokenId);
            lastClaimedScoreAt[tokenId] = 0;
            tokenOwner[tokenId] = address(0);
            _removeElement(ownedTokens[_msgSender()], tokenId);
        }
    }

    function burnAndAirdrop(
        address burnAndAirdropContractAddress,
        uint256[] memory tokenIds
    ) external nonReentrant {
        require(burnAndMintEnable, "Burn And Mint Not Enabled");
        require(tokenIds.length % 5 == 0, "Invalid Tokens Num");
        uint256 quantity = tokenIds.length / 5;
        require(quantity > 0,"Qauntity Must Greater Than Zero");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
        IBurnAndAirdropContract burnAndAirdropContract = IBurnAndAirdropContract(burnAndAirdropContractAddress);
        burnAndAirdropContract.airdrop(_msgSender(), quantity);
    }
    
    function claimScore() internal {
        uint256 addScore;
        uint256 times;
        uint256[] memory tokenIds = ownedTokens[_msgSender()];
        if (tokenIds.length > 0 && tokenIds.length < 5) {
            times = 1;
        } else if (tokenIds.length >= 5 && tokenIds.length < 10) {
            times = 2;
        } else if (tokenIds.length >= 10 && tokenIds.length < 15) {
            times = 3;
        } else {
            times = 5;
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            addScore += (block.timestamp - lastClaimedScoreAt[tokenId]) * times;
            lastClaimedScoreAt[tokenId] = block.timestamp;
        }
        totalScoreOf[_msgSender()] += addScore;
    }

    function _removeElement(
        uint256[] storage _array,
        uint256 _element
    ) internal {
        uint256 length = _array.length;
        for (uint256 i; i < length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

    function burn(uint256 tokenId) internal {
        require(_msgSender() == ownerOf(tokenId), "Not Token Owner");
        _burn(tokenId);
    }

    function setMintEnable() external onlyOwner {
        mintEnable = !mintEnable;
    }

    function setStakingEnable() external onlyOwner {
        stakingEnable = !stakingEnable;
    }

    function setBurnAndMintEnable() external onlyOwner {
        burnAndMintEnable = !burnAndMintEnable;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId));
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}