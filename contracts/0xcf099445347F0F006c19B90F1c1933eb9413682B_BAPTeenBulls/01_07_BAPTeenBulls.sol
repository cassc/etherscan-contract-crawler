// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BAPTeenBulls is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;
    // Public attributes for Manageable interface
    string public project;
    uint256 public maxSupply;
    bool public open;
    string public baseURI;
    mapping(uint256 => string) private _tokenURIs;
    address public orchestrator;

    constructor(
        string memory _project,
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721A(_name, _symbol) {
        project = _project;
        maxSupply = _maxSupply;
    }

    function airdrop(address to, uint256 amount) public nonReentrant onlyOwner {
        require(_totalMinted() + amount <= maxSupply, "Invalid amount");
        _safeMint(to, amount);
    }

    function generateTeenBull() external onlyOrchestrator {
        require(open, "Contract closed");
        require(_totalMinted() < maxSupply, "Supply limit");
        buy(tx.origin);
    }

    function burnTeenBull(uint256 tokenId) external onlyOrchestrator {
        require(open, "Contract closed");
        _burn(tokenId, true);
    }

    function buy(address to) internal {
        uint256 _totalMinted = _totalMinted();
        _safeMint(to, 1);
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function setTokenURI(uint256 id, string memory newURL) external onlyOwner {
        require(bytes(newURL).length > 0, "New URL Invalid");
        require(_exists(id), "Invalid Token");
        _tokenURIs[id] = newURL;
    }

    function setMaxSupply(uint256 _totalSupply) external onlyOwner {
        require(_totalSupply >= _totalMinted(), "Total supply too low");
        maxSupply = _totalSupply;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOrchestrator() {
        require(
            orchestrator == _msgSender(),
            "Ownable: caller is not the orchestrator"
        );
        _;
    }

    function setOrchestrator(address newOrchestrator) external onlyOwner {
        require(newOrchestrator != address(0), "200:ZERO_ADDRESS");
        orchestrator = newOrchestrator;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}