// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//   __   __    __  __   __ __    __   __     _____      _____   ______  _ __     ______
//  /\_\ /_/\ /\  /\  /\/_/\__/\ /_/\ /\_\   / ___ \    / ___ \ / ____/\/_ \ \   / ____/\
// ( ( (_) ) )\ \ \/ / /) ) ) ) )) ) \ ( (  / /\_/\ \  / /\_/\ \) ) __\/  ) ) )  ) ) __\/
//  \ \___/ /  \ \__/ //_/ /_/ //_/   \ \_\/ /_/ (_\ \/ /_/ (_\ \\ \ \   / / /    \ \ \
//  / / _ \ \   \__/ / \ \ \_\/ \ \ \   / /\ \ )_/ / /\ \ )_/ / /_\ \ \  \ \ \_   _\ \ \
// ( (_( )_) )  / / /   )_) )    )_) \ (_(  \ \/_\/ /  \ \/_\/ /)____) )  ) )__/\)____) )
//  \/_/ \_\/   \/_/    \_\/     \_\/ \/_/   \ ____/    \ ____/ \____\/   \/___\/\____\/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HYPN00S1S is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 333;
    uint256 public MINT_PRICE = .0049 ether;
    uint256 public MAX_PER_TX = 3;
    string public baseURI = "ipfs://QmX6pWx3P3Yb6sbrwADD4MDk6Sm9QEiRn4st52dywDrqM4/";
    bool public paused = true;
    mapping(address => uint256) public MINT_PER_WALLET;

    constructor() ERC721A("HYPN00S1S", "HYPN0") {}

    function mint(uint256 _quantity) external payable {
        require(!paused, "M1NT PAUS3D!!!");
        require((totalSupply() + _quantity) <= MAX_SUPPLY,"MAX SUPPLY EXC33D3D!!!");
        require((MINT_PER_WALLET[msg.sender] + _quantity) <= MAX_PER_TX,"MAX M1NT EXC33D3D!!!");
        require(msg.value >= (MINT_PRICE * _quantity), "WR0NG M1NT PR1C3!!!");

        MINT_PER_WALLET[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(address to, uint256 amount) external onlyOwner {
        _safeMint(to, amount);
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function SET_BASEURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function START_SALE() external onlyOwner {
        paused = !paused;
    }

    function SET_PRICE(uint256 _newPrice) external onlyOwner {
        MINT_PRICE = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}