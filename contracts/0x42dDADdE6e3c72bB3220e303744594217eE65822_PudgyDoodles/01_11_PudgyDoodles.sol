//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract PudgyDoodles is ERC721A {
    using Strings for uint256;

    modifier onlyOwner() {
        require(owner == _msgSender(), "PudgyDoodles: not owner");
        _;
    }

    event StageChanged(Stage from, Stage to);

    enum Stage {
        Pause,
        Public
    }

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public freeSupply = 8888;
    uint256 public price = 0.005 ether;
    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public constant MAX_MINT_PER_WALLET_FREE = 2;
    address public immutable owner;

    mapping(address => bool) public addressFreeMinted;

    Stage public stage;
    string public baseURI;
    string internal baseExtension = ".json";

    constructor() ERC721A("PudgyDoodles", "PGDD") {
        owner = _msgSender();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "PudgyDoodles: not exist");
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : ""
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // WORK ONCE!
    function freeMint(uint256 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "PudgyDoodles: exceed max supply."
        );
        require(
            addressFreeMinted[msg.sender] == false,
            "PudgyDoodles: already free minted"
        );
        if (stage == Stage.Public) {
            if (currentSupply < freeSupply) {
                require(
                    _quantity <= MAX_MINT_PER_WALLET_FREE,
                    "PudgyDoodles: too many free mint per tx."
                );
            } else {
                revert("PudgyDoodles: free mint it out");
            }
        } else {
            revert("PudgyDoodles: mint is pause.");
        }
        addressFreeMinted[msg.sender] = true;
        _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "PudgyDoodles: exceed max supply."
        );
        if (stage == Stage.Public) {
            require(
                _quantity <= MAX_MINT_PER_TX,
                "PudgyDoodles: too many mint."
            );
            require(
                msg.value >= price * _quantity,
                "PudgyDoodles: insufficient fund."
            );
        } else {
            revert("PudgyDoodles: mint is pause.");
        }
        _safeMint(msg.sender, _quantity);
    }

    function setStage(Stage newStage) external onlyOwner {
        require(stage != newStage, "PudgyDoodles: invalid stage.");
        Stage prevStage = stage;
        stage = newStage;
        emit StageChanged(prevStage, stage);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFreeSupply(uint256 newFreeSupply) external onlyOwner {
        freeSupply = newFreeSupply;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        _withdraw(msg.sender, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}