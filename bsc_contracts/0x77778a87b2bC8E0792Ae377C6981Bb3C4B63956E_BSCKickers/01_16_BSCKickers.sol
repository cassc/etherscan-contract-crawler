// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BSCKickers is Ownable, ERC721Enumerable, ReentrancyGuard {
    using SafeMath for uint256;

    string private _customBaseURI = "https://bsckickers.fra1.digitaloceanspaces.com/metadata/";
    uint256 public MAX_SUPPLY = 1000;
    uint256 public MINTING_PRICE = 0;
    uint256 public MAX_TX = 1;
    bool public mintingActive = false;
    bool public wlMintingActive = true;
    mapping(address => uint256) public wlClaim;
    mapping(uint256 => bool) public isDead;

    address[] public ADMIN_ADDRESS;

    constructor() ERC721("BSCKickers", "Kicker") {}

    function mint(uint256 _amount, address _to) external payable nonReentrant {
        require(mintingActive, "Minting not active");
        require(_amount.add(totalSupply()) <= MAX_SUPPLY, "Amount would exceed max supply.");
        require(msg.value == MINTING_PRICE.mul(_amount), "Incorrect BNB value sent.");
        require(_amount <= MAX_TX, "Too many mints per transaction");

        if (wlMintingActive) {
            require(wlClaim[_to] >= _amount, "Not enough whitelist spots");
            wlClaim[_to] = wlClaim[_to].sub(_amount);
        }

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, totalSupply() + 1);
        }
    }

    // Add admin ability to manipulate rewards balance
    function setAdmin(address _addr, uint256 _index) external onlyOwner {
        ADMIN_ADDRESS[_index] = _addr;
    }

    // Give a new address admin rights to edit wallet balances
    function addAdmin(address _addr) external onlyOwner {
        ADMIN_ADDRESS.push(_addr);
    }

    // Remove admin access for address
    function removeAdmin(address _addr) external onlyOwner {
        for (uint256 i = 0; i < ADMIN_ADDRESS.length; i++) {
            if (ADMIN_ADDRESS[i] == _addr) {
                ADMIN_ADDRESS[i] = ADMIN_ADDRESS[ADMIN_ADDRESS.length - 1];
                ADMIN_ADDRESS.pop();
            }
        }
    }

    // Returns true if the address _addr has admin rights to edit credit balance.
    function isAdmin(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < ADMIN_ADDRESS.length; i++) if (ADMIN_ADDRESS[i] == _addr) return true;
        return false;
    }

    function editDeadStatus(uint256[] calldata _tokenId, bool[] calldata _status) external {
        require(isAdmin(address(msg.sender)), "Sender does not have admin rights!");
        for (uint256 i = 0; i < _tokenId.length; i++) isDead[_tokenId[i]] = _status[i];
    }

    // Returns a bool array of dead status for respective token IDs.
    // True means dead, false means alive
    function getDeadStatus(uint256[] calldata _tokenIds) external view returns (bool[] memory) {
        bool[] memory deadStatus = new bool[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0 && _tokenIds[i] <= totalSupply(), "Invalid token ID!");
            deadStatus[i] = isDead[_tokenIds[i]];
        }
        return deadStatus;
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
        require(_amount <= 500, "Maximum allowed total supply is 500!");
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