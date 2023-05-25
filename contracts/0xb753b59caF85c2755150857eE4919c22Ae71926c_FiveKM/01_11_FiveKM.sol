// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

//contract code reference from XRC and GCLX, thanks !

contract FiveKM is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished
    }
    Status public status;
    string public baseURI;
    uint256 public tokensReserved;

    uint256 public constant MAX_MINT_PER_ADDR = 2;
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant RESERVE_AMOUNT = 555;
    uint256 public constant PRICE = 0.05 * 10**18; // 0.05 ETH

    event StatusChanged(Status status);
    event Minted(address minter, uint256 amount);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("5KM APP", "5KM") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reserve(address recipient) external onlyOwner {
        require(recipient != address(0), "5KM: zero address.");
        require(
            totalSupply() + 1 <= MAX_SUPPLY,
            "5KM: max supply exceeded."
        );
        require(
            tokensReserved + 1 <= RESERVE_AMOUNT,
            "5KM: max reserve amount exceeded."
        );

        _safeMint(recipient, 1);
        tokensReserved += 1;
        emit ReservedToken(msg.sender, recipient, 1);
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "5KM: not ready.");
        require(
            tx.origin == msg.sender,
            "5KM: contract is not allowed to mint."
        );
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "5KM: max mint amount per wallet exceeded."
        );

        require(
            totalSupply() + quantity + RESERVE_AMOUNT - tokensReserved <=
            MAX_SUPPLY,
            "5KM: max supply exceeded."
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "5KM: need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "5KM: no balance to withdraw.");
        (bool ok, ) = payable(owner()).call{value: balance}("");

        require(ok, "Transfer failed.");
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

}