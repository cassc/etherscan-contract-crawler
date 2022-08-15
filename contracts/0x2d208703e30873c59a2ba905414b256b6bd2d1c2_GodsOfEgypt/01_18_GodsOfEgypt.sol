// SPDX-License-Identifier: MIT
/*
 ██████╗  ██████╗ ███████╗
██╔════╝ ██╔═══██╗██╔════╝
██║  ███╗██║   ██║█████╗
██║   ██║██║   ██║██╔══╝
╚██████╔╝╚██████╔╝███████╗
 ╚═════╝  ╚═════╝ ╚══════╝
Contract by Novem - https://novem.dev
*/
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./ERC2981ContractWideRoyalties.sol";
import "./VRFv2Consumer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GodsOfEgypt is ERC721A, VRFv2Consumer, ERC2981ContractWideRoyalties {
    using Strings for uint256;

    string public baseURI = "ipfs://QmeLUkyYKK4GmbpEPECdgMx2UF9xG4epx8hFVAmFtPGcA6?";
    string public uriSuffix = ".json";
    bool public saleActive = false;

    bool public noblelistSaleActive = false;  // Sale Type 0
    bool public preSaleActive = false;        // Sale Type 1

    bool public contractSealed = false;

    // Special Price and supply
    uint256 constant public NOBLELIST_PRICE = 0.042 ether;
    uint256 constant public NOBLELIST_MAX_SUPPLY = 1000;
    uint256 constant public PRE_PRICE = 0.049 ether;
    uint256 constant public PRE_MAX_SUPPLY = 2000;

    // Overall price and supply
    uint256 constant public TOKEN_PRICE = 0.052 ether;
    uint256 public TOKEN_MAX_SUPPLY = 7532;

    // EIP 2981 Standard Implementation
    address constant public ROYALTY_RECIPIENT = 0xb4eaa204aEbd7005a88dbe46Cf7A96C54ad56FB1;
    address constant public DEV_TEAM = 0x2bdB46441007C395bcC5B97df3941FDfb9d5D78D; // Novem Wallet Address
    uint256 constant public ROYALTY_PERCENTAGE = 500;

    // Protection
    mapping (address => uint256) nlAmountMinted;
    mapping (address => uint256) preAmountMinted;
    mapping (address => uint256) amountMinted;
    uint256 public mintLimit = 5;

    mapping (uint256 => string) gods;

    address private _adminSigner = 0xA39A33AD9CD3f55f227aB0567b6CB9ad4b8e37EF;

    struct Coupon {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}

    constructor (uint64 subscriptionId, address vrfCoordinator, bytes32 m_keyHash)
        ERC721A("GodsOfEgypt", "GOE")
        VRFv2Consumer(subscriptionId, vrfCoordinator, m_keyHash)
    {
        _setRoyalties(ROYALTY_RECIPIENT, ROYALTY_PERCENTAGE);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (bytes(gods[tokenId]).length > 0) {
            return gods[tokenId];
        }
        string memory bURI = _baseURI();
        return bytes(bURI).length > 0 ? string(abi.encodePacked(bURI, tokenId.toString(), uriSuffix)) : '';
    }

    function updateMetadata(uint256 tokenId, string memory newUri) public onlyOwner {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        gods[tokenId] = newUri;
    }

    function activateSale(uint24 mintLimit_, bool active, bool nlSale, bool preSale) public onlyOwner {
        mintLimit = mintLimit_;
        saleActive = active;
        noblelistSaleActive = nlSale;
        preSaleActive = preSale;
    }

    // Efficient and easy way to seal contract to avoid any future modification of baseUri
    function sealContract() public onlyOwner {
        require(!contractSealed, "Contract has been already sealed");
        contractSealed = true;
    }

    function setAdminSigner(address adminSigner) public onlyOwner {
        require(!contractSealed, "Contract has been already sealed");
        _adminSigner = adminSigner;
    }

    // Mint
    function mint(uint256 quantity, Coupon memory coupon) public payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(saleActive, "The sale is not active");
        uint256 tokenPrice = TOKEN_PRICE;

        if (noblelistSaleActive) {
            require(totalSupply() + quantity <= NOBLELIST_MAX_SUPPLY, "Not enough Artifacts left");
            require(nlAmountMinted[msg.sender] + quantity <= mintLimit, "You can't mint more than that for now");
            tokenPrice = NOBLELIST_PRICE;
        } else if(preSaleActive) {
            require(totalSupply() + quantity <= PRE_MAX_SUPPLY + NOBLELIST_MAX_SUPPLY, "Not enough Artifacts left");
            require(preAmountMinted[msg.sender] + quantity <= mintLimit, "You can't mint more than that for now");
            tokenPrice = PRE_PRICE;
        } else {
            require(amountMinted[msg.sender] + quantity <= mintLimit, "You can't mint more than that for now");
        }
        require(totalSupply() + quantity <= TOKEN_MAX_SUPPLY, "Not enough Artifacts left");

        uint256 couponType = noblelistSaleActive ? 0 : (preSaleActive ? 1 : 2);

        if(couponType != 2){
            bytes32 digest = keccak256(abi.encode(couponType, msg.sender));
            require(_isVerifiedCoupon(digest, coupon), 'Invalid coupon');
        }

        require(msg.value >= tokenPrice * quantity, "Wrong price");

        // Increment protection variable to make sure minter never goes over the set limit
        if (noblelistSaleActive) {
            nlAmountMinted[msg.sender] += quantity;
        } else if(preSaleActive) {
            preAmountMinted[msg.sender] += quantity;
        } else {
            amountMinted[msg.sender] += quantity;
        }
        _safeMint(msg.sender, quantity); // Minting of the token(s)
    }

    // Airdrop
    function airdrop(address[] memory receivers, uint256 quantity) public onlyOwner {
        require(totalSupply() + (quantity*receivers.length) <= TOKEN_MAX_SUPPLY, "Not enough Artifacts left");
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], quantity);
        }
    }

    // Withdraw funds from the contract
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x1BEAe2eF143f7f974eb734b9e8369781Db08F0CC).transfer(balance*21/100);
        payable(0x6503183167cCAb9cebA25109d2f7776206e83A46).transfer(balance*1/100);
        payable(0xC622f4b3aE6677276bB3bbe373AD8b1843D4439b).transfer(balance*1/100);
        payable(0xD8faF502EBe2FE783710b1781782c14f566050df).transfer(balance*1/100);
        payable(0x29cb02180D8d689918cE2c50A3357798d6Fd9283).transfer(balance*1/100);
        payable(0xCabB179ca4f9360e4761121A2363a3AF5587B1aA).transfer(balance*1/100);
        payable(0xB2d49f053269904ca13459Cb6Bb3555a3206fe75).transfer(balance*1/100);
        payable(0xB49395Ecf078207e64ee53C045D454051a9237b7).transfer(balance*1/100);
        payable(0x7376981831c171be0e3dCdDd423D46cf0B5aF917).transfer(balance*1/100);
        payable(0xF813013666Ee8f123Bb821fb36aCb27eb7b4eC9F).transfer(balance*3/200);
        payable(0x9EFC6C6243965FE6288d3712b9c595855B1D6EE6).transfer(balance*21/100);
        payable(0xeC7100ABDbCf922f975148C6516BC95696cA0eF6).transfer(balance*1/100);
        payable(0xc1A99F382dD0c6F3A6fcf80dFaF4Da929dBE7DED).transfer(balance*3/200);
        payable(0xb3CBc74EFcf9E478cddb26630db76f7349407d5A).transfer(balance*5/100);
        payable(0xf69f1CB31792c8B481f5AA4f124546FBD33c2F44).transfer(balance*1/100);
        payable(0x4BCfc5fD38Bb19d137eBE9D1119246C997b5877F).transfer(balance*1/100);
        payable(0x421470C15Bd386b3d75648682c19Bb968C1B3B56).transfer(balance*1/100);
        payable(0xCC660f21E4263dF1c36453F8853077188CbE5062).transfer(balance*1/100);
        payable(0x145C926cF21E89802A377590bE227bFdEBCCdDE9).transfer(balance*1/100);
        payable(0x355148B29aE2F861958D9525949cBcB639573387).transfer(balance*2/100);
        payable(0x05508d3A925Aa08CAC18f8Da1b0934A712870901).transfer(balance*1/100);
        payable(0x5050Abb6cB8D5000Aad66f5754168B578583dd45).transfer(balance*1/100);
        payable(0xD1b5678adB084817807FEFB58B829deeC536229b).transfer(balance*1/100);
        payable(DEV_TEAM).transfer(balance*5/100);
        payable(0xc9f2697736BDf75Feb8A2f77905C0Ef273a102b0).transfer(balance*1/100);
        payable(0x3bAE9D1a0D5CeB9Df403DD6F0c088ca086C49A01).transfer(balance*4/100);
        payable(0x8f973f7bAE949Eb900233299FF6A5F2a09ef5168).transfer(balance*21/100);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    // EIP 2981 Standard Implementation
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool)
    {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), 'ECDSA: invalid signature');
        return signer == _adminSigner;
    }

    function setBaseURI(string memory _uriPrefix) public onlyOwner {
        baseURI = _uriPrefix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}