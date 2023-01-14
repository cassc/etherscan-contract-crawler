// contracts/HouseTokenWrapper.sol
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface Iwrapper {
    function changeHolder(address nft, uint256 id, address usr) external;
}

contract HouseWrap {
    address                                         public wrapper;
    address                                         public holder;
    uint256                                         public constant totalSupply = 1;
    mapping(address => mapping(address => uint256)) public allowance;
    string                                          public symbol;
    uint8                                           public constant decimals = 0;
    string                                          public name = "HouseWrap";
    IERC721Metadata                                 public immutable erc721;
    uint256                                         public immutable tokenId;

    constructor(
        address w,
        IERC721Metadata t,
        uint256 id,
        string memory tokenSymbol
    ) {
        wrapper = w;
        erc721 = t;
        tokenId = id;
        symbol = tokenSymbol;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function tokenURI() external view returns (string memory)  {
        return erc721.tokenURI(tokenId);
    }

    function balanceOf(address account) external view returns (uint256) {
        return account == holder ? totalSupply : 0;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(amount == 1, "HouseTokenWrapper: invalid-amount");
        require(sender == holder, "HouseTokenWrapper: insufficient-balance");
        require(recipient != address(0), "HouseTokenWrapper: recipient is the zero address");

        if (sender != msg.sender) {
            require(
                allowance[sender][msg.sender] >= amount,
                "HouseTokenWrapper: insufficient-approval"
            );
            allowance[sender][msg.sender] = allowance[sender][msg.sender] - amount;
        }

        holder = recipient;
        Iwrapper(wrapper).changeHolder(address(erc721), tokenId, recipient);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function withdraw() external {
        require(holder != address(0), "HouseTokenWrapper: holder is the zero address");
        require(holder == msg.sender, "HouseTokenWrapper: only holder");

        erc721.transferFrom(address(this), holder, tokenId);
        holder = address(0);
        Iwrapper(wrapper).changeHolder(address(erc721), tokenId, address(0));
        emit Transfer(holder, address(0), totalSupply);
    }

    function deposit() public {
        erc721.transferFrom(msg.sender, address(this), tokenId);
        holder = msg.sender;
        Iwrapper(wrapper).changeHolder(address(erc721), tokenId, msg.sender);
        emit Transfer(address(0), holder, totalSupply);
    }

    function depositAndApprove(address spender) external {
        deposit();
        approve(spender, totalSupply);
    }
}