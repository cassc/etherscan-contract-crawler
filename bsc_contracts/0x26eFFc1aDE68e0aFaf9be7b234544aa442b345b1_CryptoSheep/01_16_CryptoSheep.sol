// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CryptoSheep is Ownable, ERC721Enumerable, ReentrancyGuard {
    using SafeMath for uint256;

    string private _customBaseURI = "https://cryptosheep.fra1.digitaloceanspaces.com/metadata/";
    uint256 public MAX_SUPPLY = 1000;
    uint256 public MINTING_PRICE = 0.125 ether;
    uint256 public MAX_TX = 10;
    uint256 public airdropCounter = 0;
    bool public mintingActive = false;
    bool public wlMintingActive = true;
    mapping(address => uint256) public wlClaim;

    constructor() ERC721("CryptoSheep", "CS") {}

    function mint(uint256 _amount, address _to) external payable nonReentrant {
        require(mintingActive, "Minting not active");
        require(_amount.mul(5).add(totalSupply()) <= MAX_SUPPLY, "Amount would exceed max supply.");
        require(msg.value == MINTING_PRICE.mul(_amount), "Incorrect BNB value sent.");
        require(_amount <= MAX_TX, "Too many mints per transaction");

        if (wlMintingActive) {
            require(wlClaim[_to] >= _amount, "Not enough whitelist spots");
            wlClaim[_to] = wlClaim[_to].sub(_amount);
        }

        for (uint256 i = 0; i < _amount.mul(5); i++) {
            _safeMint(_to, totalSupply() + 1);
        }
    }

    function airdrop(uint256 _amount, address _to) external onlyOwner {
        require(_amount.mul(5).add(totalSupply()) <= MAX_SUPPLY, "Amount would exceed max supply.");
        require(_amount.add(airdropCounter) <= 20, "Amount would exceed airdrop limit.");
        require(_amount <= MAX_TX, "Too many mints per transaction");

        airdropCounter = airdropCounter.add(_amount);

        for (uint256 i = 0; i < _amount.mul(5); i++) {
            _safeMint(_to, totalSupply() + 1);
        }
    }

    function addWL(address[] calldata to, uint256[] calldata amount) external onlyOwner {
        for (uint256 i = 0; i < amount.length; i++) {
            // Add WL address
            wlClaim[to[i]] += amount[i];
        }
    }

    function setWL(address[] calldata to, uint256[] calldata amount) external onlyOwner {
        for (uint256 i = 0; i < amount.length; i++) {
            // Set WL address
            wlClaim[to[i]] = amount[i];
        }
    }

    function setMaxSupply(uint256 _amount) external onlyOwner {
        require(_amount <= 1000, "Maximum allowed total supply is 1000!");
        MAX_SUPPLY = _amount;
    }

    function setWLMintingActive(bool _value) external onlyOwner {
        wlMintingActive = _value;
    }

    function setMaxTx(uint256 _amount) external onlyOwner {
        MAX_TX = _amount;
    }

    function setMintingActive(bool _value) external onlyOwner {
        mintingActive = _value;
    }

    // Change the price of minting for one NFT
    function setPrice(uint256 _amount) external onlyOwner {
        MINTING_PRICE = _amount;
    }

    /**
     * @notice returns to base URI used for tokenURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _customBaseURI;
    }

    /**
     * @notice changes the base URI.
     * Can only be called by the contract owner.
     */
    function setBaseURI(string memory _newURI) external onlyOwner {
        _customBaseURI = _newURI;
    }

    function withdraw() external onlyOwner {
        payable(address(msg.sender)).transfer(address(this).balance);
    }

    function withdrawERC20(address _addr) external onlyOwner {
        IERC20(_addr).transfer(address(msg.sender), IERC20(_addr).balanceOf(address(this)));
    }
}