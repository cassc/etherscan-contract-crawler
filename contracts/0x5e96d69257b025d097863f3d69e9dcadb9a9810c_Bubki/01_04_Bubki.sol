//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";


contract Bubki is ERC721, Ownable {

    // We are donating to https://unchain.fund/
    address public UKRAINE_ETH_ADDRESS = 0x10E1439455BD2624878b243819E31CfEE9eb721C;
    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public tokenCost = 0.05 ether;
    uint256 public maxMintPerTx = 100;
    bool public isSaleActive;
    bool public metadataFrozen;
    uint256 public totalSupply;
    string public baseURI;

    constructor() ERC721("Bubki for Ukraine", "Bubki") {}

    function mint(uint256 _count) external payable {
        require(isSaleActive);
        require(_count <= maxMintPerTx);

        uint256 currentId = totalSupply;

        unchecked {
            require(currentId + _count <= MAX_SUPPLY);
            require(msg.value == _count * tokenCost);

            for (uint256 i; i < _count; ++i) {
                // 99% sure this check is not necessary,
                // because totalSupply will force mint to always increment to a place where ownerOf == 0x0
                // require(ownerOf[id] == address(0), "ALREADY_MINTED");

                ownerOf[currentId + i] = msg.sender;
                emit Transfer(address(0), msg.sender, currentId + i);
            }

            balanceOf[msg.sender] += _count;
            totalSupply += _count;
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(ownerOf[_tokenId] != address(0));
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function updateTokenCost(uint256 _tokenCost) external onlyOwner {
        tokenCost = _tokenCost;
    }

    function updateMaxMintPerTx(uint256 _maxMintPerTx) external onlyOwner {
        maxMintPerTx = _maxMintPerTx;
    }

    function updateBaseURI(string memory _baseURI) external onlyOwner {
        require(metadataFrozen == false, "METADATA_FROZEN");
        baseURI = _baseURI;
    }

    function freezeBaseURI() external onlyOwner {
        metadataFrozen = true;
    }

    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /**
     * @dev Allows update to charity address in the event that the deployed address
     * is incorrect or has to be changed. Only can be called by owner or the charity's
     * address (if EOA).
     */
    function updateWithdrawAddress(address _newAddress) external onlyReceiverOrOwner {
        UKRAINE_ETH_ADDRESS = _newAddress;
    }

    /**
     * @dev Throws if not called by owner or withdrawal target
     */
    modifier onlyReceiverOrOwner() {
        require(msg.sender == UKRAINE_ETH_ADDRESS || msg.sender == owner());
        _;
    }

    function transferFunds() external {
        uint256 balance = address(this).balance;

        (bool transferTx, ) = payable(UKRAINE_ETH_ADDRESS).call{value: balance}("");
        require(transferTx);
    }
}