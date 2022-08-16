pragma solidity 0.8.16;
// SPDX-License-Identifier: MIT
import "./ERC1155Supply.sol";
import "./Ownable.sol";

contract BullsStonerClub is ERC1155Supply, Ownable {
    mapping(uint256 => string) public tokenURI;

    string public name;
    string public symbol;
    uint256 public publicCost = 0.04 ether;
    bool public paused = true;
    uint256 public maxAmount = 10;
    uint256 public GoldenMaxSupply = 3780;
    uint256 public DiamondMaxSupply = 420;

    constructor() ERC1155("") {
        name = "Stoner Bulls Club";
        symbol = "SBC";
        tokenURI[
            1
        ] = "ipfs://bafkreiggkctslhyrwmzxdjzgsiiekoqsy3ocq3ytxu6zxqtpb4hgy7qx7m"; // Golden
        tokenURI[
            2
        ] = "ipfs://bafkreieqp2su2tbbonmqakazs4lsqfdmril27fdyco3kew56sffxlyy3ka"; // Diamond
    }

    function mint(uint256 _id, uint256 quantity) external payable {
        require(bytes(tokenURI[_id]).length > 0, "Token Doesn't Exist");
        uint256 supply = totalSupply(_id);
        require(!paused, "The contract is paused!");
        require(quantity > 0, "Quantity Must Be Higher Than Zero");
        if (_id == 1) {
            require(supply + quantity <= GoldenMaxSupply, "Max Supply Reached");
        } else {
            require(
                supply + quantity <= DiamondMaxSupply,
                "Max Supply Reached"
            );
        }

        if (msg.sender != owner()) {
            require(
                quantity <= maxAmount,
                "You're Not Allowed To Mint more than maxMint Amount"
            );
            require(msg.value >= publicCost * quantity, "Insufficient Funds");
        }
        _mint(msg.sender, _id, quantity, "");
    }

    // internal
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "Token Doesn't Exist");
        return tokenURI[_id];
    }

    function setCost(uint256 _publicCost) public onlyOwner {
        publicCost = _publicCost;
    }

    function setMax(uint256 _maxAmount) public onlyOwner {
        maxAmount = _maxAmount;
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        (bool ts, ) = payable(owner()).call{value: address(this).balance}("");
        require(ts);
    }
}