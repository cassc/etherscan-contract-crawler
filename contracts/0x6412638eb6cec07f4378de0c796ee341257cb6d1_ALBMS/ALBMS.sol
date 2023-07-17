/**
 *Submitted for verification at Etherscan.io on 2023-07-02
*/

// SPDX-License-Identifier: MIT

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//       ___________      _______        __________                 //
//      /           \____/       \______/          \  ____          //
//     /    _____    ___________      ____   _____  \/   /          //
//    /    /     \   \____\ \___\  \_____ \  \    \_____/           //
//    \    \      \________\ \_____/ __  \ \  \______________       //
//    /    /   ______  _____\ \  \ \ \ \__\ \                \      //
//    \    \   \__   \ \____/  \  \ \ \_____/_______________  \     //
//     \    \_____\   \    /   /  /  \  ___ \               \  \    //
//      \_____________/   /___/  /____\ \__\ \______________/  /    //
//         \___________________________\_____/________________/     //
//                                                                  //
//                                                          GERBS   //
//                                                                  //
//////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.12;

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC1155 {
    mapping(uint256 => mapping(address => uint256)) private balances;
    mapping(uint256 => string) private _uris;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    event AddressAllowed(address indexed addr);

    function _mint(address account, uint256 id, uint256 amount) internal virtual {
        balances[id][account] += amount;
        emit TransferSingle(msg.sender, address(0), account, id, amount);
    }

    function setURI(uint256 id, string memory newURI) public {
        _uris[id] = newURI;
        emit URI(newURI, id);
    }

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        return balances[id][account];
    }

    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) public {
        require(to != address(0), "Invalid receiver address");
        require(
            msg.sender == from || operatorApprovals[from][msg.sender],
            "Not approved to transfer tokens"
        );
        require(balances[id][from] >= amount, "Insufficient balance");

        balances[id][from] -= amount;
        balances[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (isContract(to)) {
            bytes4 onERC1155ReceivedSelector = IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                from,
                id,
                amount,
                ""
            );
            require(
                onERC1155ReceivedSelector == 0xf23a6e61,
                "Transfer not accepted by the receiver contract"
            );
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount//,
        //bytes calldata data
    ) external {
        transferFrom(from, to, id, amount);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Invalid operator");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return operatorApprovals[account][operator];
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        require(balances[id][account] >= amount, "Insufficient balance");

        balances[id][account] -= amount;
        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    function uri(uint256 id) public view returns (string memory) {
        return _uris[id];
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ALBMS is ERC1155, Ownable {
    uint256 public ALBUM_ID;
    uint256 public mintPrice;
    uint256 public totalMints;
    bool public publicLive;
    bool public allowLive;
    address payable[] public addresses;
    mapping(address => bool) public allow_addresses;
    address[] public allowed_addresses;

    constructor() {
        ALBUM_ID = 0;
        mintPrice = 10000000000000000;
        totalMints = 0;
        publicLive = false;
        allowLive = false;

        // Define your initial addresses here
        address[50] memory initialAddresses = [0x07f67984844248542FdACC84A95ce24BF97513b9,0x1Da2c0561cA0cDE90f16448751723fcc0b87FEf9,0x20e6af36fD433821f704B12ec03f644dc406A5Dc,0x26b13e3924897C03715489361459b869Af949640,0x2760564775dBf12C81B92d19718185fA6D663fe8,0x29d2B425dC9881eb1C55ab29d1a3393F7A2F5678,0x2a0ac9AB9fBBbF12a4223eEdD5e92fb306117952,0x2e69fc5871C642D045354A3988D1F071102B49aE,0x31fA8e708cBA6eeCB355338b393621d4CA7743F4,0x31fbaa23aD224E32B2626985e6B70ff75cB6AbE5,0x35224C95aa3E53a30cc3F6f64540618892a568D7,0x3c9a951B0D30422964Ac9162F0E93bA4dbF9157D,0x43f427bAA039404a949fA272bD543C7D9Efc9C71,0x48BFB74bEF9bfa3C5896e8A168b413d8458146f4,0x496e3833217AeD6a1738F986829F941cE71c81cF,0x4bcaC160CE0Fb9015C2b8C28726cb1EAc879a960,0x52F1E8C4C156761a2F602341768A9aecDFA4BA38,0x567B5E79cE0d465a0FF1e1eeeFE65d180b4C5D41,0x621FE8A9713139603E696985fD50e2D550dE7C08,0x68375427c29995B277ad343AA89BE591926C6088,0x6E69860885B367073D2347dD93eEC649d7f664c3,0x75d514b6040727C19ae06aE8F1a1c7912c4C91C0,0x770d0A50f87298459C13D570011fFae3C045C05E,0x7933231775dEc3f3c80039DEbd7E3afD8A81f674,0x7Ec0ba2787879E33bDe94A6288534Dcf45F1C132,0x7e89DAF03D3E81d81bA6a242FD05646FaEF524B8,0x7e8C38Ad50622c0b26906C9Cf81D2825fC78A38B,0x898BB3e7CEEb3Bb0AE26A7c291d9562841ff332F,0x8A19EE2B23EF483C6c9B2De1e65D8c799Cd80EA1,0x8C962009Eb45FB6abC9f57a40A2c71098B01B6b8,0x945ddC5135015685E49624F2D57Ea22d766883b1,0x9764AcA501D18EA683637408E0a77424aB23eBD8,0xAfda4F57783D1b958307beAeC1Efedee0ba7943b,0xB3B876567b5005CC6AD5994684ADCcc3BFaB7246,0xB774c54B016B79bbEc24B2e8af0535E420476A08,0xBB17D6b61063FD58410e309a3F9F5dfCd44a305D,0xC1202B2da243467882439944885339f9Fd71279C,0xF823668826C24Ae56e3976EcE3Ae90De5d808Df5,0xFcf8dDD2d5d663e3f6B9b952048b377bD7A3EC6A,0xa3b019710229d41537A82822bbFe5C5f8aC1b492,0xb418b7E6CeFd4a1C28B8DaBa78488884D05b0D3f,0xbb8341376AF7b802D34CAB5A894884d8420118cC,0xc06317F4721BB3d2dd1694859A227E3C38F83843,0xc7b57729663DdD90A05AF66b42e9D4f71448F099,0xd0fc88F29C456e44256ba013de787cecCE06077F,0xeeD0f2aF4C784834E547FB920DddEF784041F918,0xf9ba31763CA3445e5770cDC70284f990406bCA84,0xfCbD526ad12eFF1cBB19efe1dffFe03f687CDEEa,0xfbf24654e413C69a1e9611fF24084Cf51f70a695,0xfd72C716278894E9bc1Fda2d41F93c20A6CF91EC];

        // Convert the array to a mapping
        for (uint256 i = 0; i < initialAddresses.length; i++) {
            allow_addresses[initialAddresses[i]] = true;
        }

        createNewToken("ipfs://bafybeifqx2iq36uusgvbvaddltqu4wdggxuope6rdopnd67xl5d27mmtsq/1.json", payable(msg.sender));
    }

    function setAllowLive(bool newAllowLive) public onlyOwner {
        allowLive = newAllowLive;
    }

    function setPublicLive(bool newPublicLive) public onlyOwner {
        publicLive = newPublicLive;
    }

    function createNewToken(string memory uri_input, address payable addressInput) public payable onlyOwner {
        uint256 newAlbumId = ALBUM_ID + 1;
        _mint(msg.sender, newAlbumId, 1);
        addresses.push(addressInput);
        setURI(newAlbumId, uri_input);
        totalMints += 1;
        ALBUM_ID = newAlbumId;
    }

    function setAlbumId(uint256 newAlbumId) public onlyOwner {
        ALBUM_ID = newAlbumId;
    }

    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        mintPrice = newMintPrice;
    }

    function setTokenUri(uint256 tokenId, string memory uriInput) public onlyOwner {
        setURI(tokenId, uriInput);
        emit URI(uriInput, tokenId); // Emit event for OpenSea cache refresh
    }

    function getTokenUri(uint256 tokenId) public view returns (string memory) {
        return uri(tokenId);
    }

    function setPayout(uint256 tokenId, address payable addressInput) public onlyOwner {
        require(tokenId > 0 && tokenId <= addresses.length, "Invalid token ID");
        addresses[tokenId - 1] = addressInput;
    }

    function mintAlbum(uint256 tokenId, uint256 mintCount) public payable {
        require(publicLive, "Public mint is closed");
        require(mintCount > 0, "Invalid mint count");
        require(msg.value >= mintPrice * mintCount, "Insufficient payment");
        _mint(msg.sender, tokenId, mintCount);
        totalMints += mintCount;

        uint256 payoutAmount = msg.value;
        address payable payoutAddress = addresses[tokenId - 1];
        require(payoutAddress != address(0), "Payout address not set for the token");

        (bool success, ) = payoutAddress.call{ value: payoutAmount }("");
        require(success, "Failed to transfer funds to the payout address");
    }

    function freeMint(uint256 tokenId) public {
        require(allowLive, "Allowlist mint is closed");
        require(isAllowlisted(msg.sender), "Address not found in allowlist");
        require(!hasClaimed(msg.sender), "Free Mint already claimed by this address");
        _mint(msg.sender, tokenId, 1);
        if (msg.sender != owner) {
            allowed_addresses.push(msg.sender);
        }
        totalMints += 1;
    }

    function hasClaimed(address addr) public view returns (bool) {
        for (uint256 i = 0; i < allowed_addresses.length; i++) {
            if (allowed_addresses[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function isAllowlisted(address addr) public view returns (bool) {
        if (allow_addresses[addr]) {
            return true;
        } else {
            return false;
        }
    }
}