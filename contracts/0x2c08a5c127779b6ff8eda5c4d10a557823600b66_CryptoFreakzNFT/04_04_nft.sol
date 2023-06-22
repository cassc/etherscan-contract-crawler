// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4;

import "./ierc165.sol";
import "./ierc721.sol";
import "./ierc2981.sol";


contract CryptoFreakzNFT is IERC165,IERC721,IERC2981,IERC721Metadata {

    uint constant TOTAL_SUPPLY = 5365;

    string constant NAME = "Cryptofreakz";
    string constant SYMBOL = "FREAKZ";
    address constant ADMIN = 0xBc1A616DD3bd5559B583573fc441dc921d5A1Ab5;

    uint minted = 1000;
    
    struct tokenData {
        address tokenApproval;
        uint8 upgrades;
    }

    struct pricesData {
        uint72 Mint;
        uint80 Upgrade1;
        uint80 Upgrade2;
        uint24 RoyaltyPPM;
    }

    pricesData private prices = pricesData(
            0.004 ether,
            0,          
            0,          
            69000       
    );


    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => tokenData) private tokenDatas;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    uint constant METADATABASE_LEN = 28;
    uint constant METADATABASE_BIN = 0x68747470733A2F2F63662E3663312E64652F612F61612E6A736F6E0000000000;
    uint constant METADATABASE_SHIFT = 80;

    constructor() payable {}

    receive() external payable {}




    function mint(address to) external payable {
        uint256 price = prices.Mint;

        require(msg.sender == ADMIN || (msg.value >= price));
        require(to != address(0), "ERC721: mint to zero address");
        require(minted < TOTAL_SUPPLY);
        
        owners[minted] = to;
        balances[to]++;

        emit Transfer(address(0), to, minted);
        minted++;

        // transfer back overpayment
        if (msg.value > price) {
            (payable(msg.sender)).transfer(msg.value - price);
        }
    }


    function upgrade1(uint256 tokenId) external payable {
        upgrade(tokenId, prices.Upgrade1, 1);
    }

    function upgrade2(uint256 tokenId) external payable {
        upgrade(tokenId, prices.Upgrade2, 2);
    }

    function upgrade(uint256 tokenId, uint256 price, uint8 upgradeStep) internal {
        require((price > 0) && (tokenDatas[tokenId].upgrades == upgradeStep-1), "not available");
        require(msg.sender == ADMIN || (msg.sender == owners[tokenId] && msg.value >= price), "access denied");

        tokenDatas[tokenId].upgrades = upgradeStep;

        emit Transfer(msg.sender, msg.sender, tokenId);

        // transfer back overpayment
        if (msg.value > price) {
            (payable(msg.sender)).transfer(msg.value - price);
        }
    }



    function getMinted() external view returns(uint256) {
        return minted;
    }

    function specialMint(address addrTo, uint256 idxFrom, uint256 n) external {
        uint256 idxTo = idxFrom + n;
        require(msg.sender == ADMIN);
        require(idxTo <= minted);
        uint256 b = balances[addrTo];
        for(uint tokenId=idxFrom; tokenId<idxTo; tokenId++) {
            if (owners[tokenId] == address(0)) {
                owners[tokenId] = addrTo;
                b++;
                emit Transfer(address(0), addrTo, tokenId);
            }
        }
        balances[addrTo] = b;
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == ADMIN);
        address owner = owners[tokenId];
        require(owner != address(0));

        tokenDatas[tokenId].tokenApproval = address(0);
        delete owners[tokenId];
        balances[owner]--;

        emit Transfer(owner, address(0), tokenId);
    }

    function sendEther(address payable to, uint256 value) external {
        require(msg.sender == ADMIN);
        to.transfer(value);
    }

    function getPriceMint() external view returns(uint256) {
        return prices.Mint;
    }

    function getPriceUpgrade() external view returns(uint256, uint256) {
        return (prices.Upgrade1, prices.Upgrade2);
    }

    function setPrices(uint72 priceMint, uint80 priceUpgrade1, uint80 priceUpgrade2, uint24 RoyaltyPPM) external {
        require(msg.sender == ADMIN);
        prices = pricesData(priceMint, priceUpgrade1, priceUpgrade2, RoyaltyPPM);
    }




// Compatibility to ERC20
    function decimals() public pure returns (uint8) {
        return 0;
    }

// ERC165

    function supportsInterface(bytes4 interfaceID) external view virtual override(IERC165) returns (bool) {
        return
            interfaceID == 0x80ac58cd ||    // ERC721
            interfaceID == 0x5b5e139f ||    // ERC721Metadata
            interfaceID == 0x2a55205a;      // ERC2981
    }


// ERC721

    function balanceOf(address owner) external view virtual override(IERC721) returns (uint256) {
        require(owner != address(0), "ERC721: address zero");
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) external view virtual override(IERC721) returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable virtual override(IERC721) {
        doTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable virtual override(IERC721) {
        doTransferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable virtual override(IERC721) {
        safeTransferFrom(from, to, tokenId, bytes(""));
    }

    function approve(address approved, uint256 tokenId) external payable virtual override(IERC721) {
        require(tokenId < TOTAL_SUPPLY);
        address owner = owners[tokenId];
        require(approved != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || operatorApprovals[owner][msg.sender],
            "ERC721: access denied"
        );

        tokenDatas[tokenId].tokenApproval = approved;
        emit Approval(owner, approved, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external virtual override(IERC721) {
        require(msg.sender != operator, "ERC721: approve to caller");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) external view virtual override(IERC721) returns (address) {
        require(owners[tokenId] != address(0), "ERC721: invalid token ID");
        return tokenDatas[tokenId].tokenApproval;
    }

    function isApprovedForAll(address owner, address operator) external view virtual override(IERC721) returns (bool) {
        return operatorApprovals[owner][operator];
    }

// ERC721 Metadata

    function name() external view virtual override(IERC721Metadata) returns (string memory) {
        return NAME;
    }

    function symbol() external view virtual override(IERC721Metadata) returns (string memory) {
        return SYMBOL;
    }


    function tokenURI(uint256 tokenId) external view virtual override(IERC721Metadata) returns (string memory) {
        require(tokenId < TOTAL_SUPPLY);

        uint256 t = tokenId;
        t = ( (t % 26) | (((t/26) % 26) << 8) | ((t/676)) << 24 | (uint(tokenDatas[t].upgrades) << 27) ) << METADATABASE_SHIFT;

        assembly {
            let res := mload(0x40)          // free memory pointer
            mstore( res, 0x20 )             // data offset
            mstore( add(res, 0x20), METADATABASE_LEN )            // length
            mstore( add(res, 0x40), add(METADATABASE_BIN,t) )     // data
            mstore(0x40, add(res, 0x60))    // update free memory pointer
            return (res, 0x60)
        }

    }



// ERC721 Helper

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    return false;
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


    function doTransferFrom(address from, address to, uint256 tokenId) private {
        require(tokenId < TOTAL_SUPPLY);
        address owner = owners[tokenId];

        require(msg.sender == owner || operatorApprovals[owner][msg.sender] || tokenDatas[tokenId].tokenApproval == msg.sender, "ERC721: caller not token owner or approved");
        require(owner == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to zero address");

        tokenDatas[tokenId].tokenApproval = address(0);
        balances[owner]--;
        owners[tokenId] = to;
        balances[to]++;

        emit Transfer(from, to, tokenId);
    }


// IERC2981 Royalty Info

    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice) external view virtual override(IERC2981) returns (address receiver, uint256 royaltyAmount) {
        receiver = ADMIN;
        royaltyAmount = _salePrice * prices.RoyaltyPPM / 1000000;
    }




}