// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MagmaXYZ is ERC721A, Ownable {
    bool public private_sale_running = false;

    uint public MINT_PRICE = 0.45 ether;
    uint public constant MAX_SUPPLY = 333;

    bytes32 public merkle_root;

    string public magma_uri = "https://ipfs.io/ipfs/QmYmV1njXt1VnbEy3N1GFNp8P9sMATsa2JK7uGy5cRJA7w";

    constructor () ERC721A("Magma XYZ", "MGM") {
        _mint(0xD8e7A51Db8DD3baD4cDA2c1F73fE0AB7C8948Ca0, 1);
        _mint(0xf84d6D2dc4a432b98A7D5B3160373D33158A4C84, 1);
        _mint(0xd6a0C200c19a448a6e8cB32dd7142028BA2e160d, 1);
        _mint(0xE1e0Da672B12F7d0d025F4b52512AB1678b2c7FD, 1);
        _mint(0x20d01F676fd27C834555BBbD3D5193387D7F9864, 1);
        _mint(0x422A1c2B25EE6a05DfDe0622586eBf1a9861089f, 1);
        _mint(0xAA6B335b960AB5AD924760E66940e485f83d192e, 1);
        _mint(0xf511935B27Ede4D52Fe0BaB1A12c91A18ce37D30, 1);
        _mint(0x77FFf5d88e331c8945a8FCE36F4152B8DC00e3eB, 1);
        _mint(0xCe92d0465C705F303FAebc77Be4e6D039D1aAB9B, 1);
        _mint(0x901c20dfe0e6bef2d51d2B15111bbE1335171aD1, 1);
        _mint(0x96825C9205673F900E57D935eCFCeAb8b5174b2f, 1);
        _mint(0x0482940b6FbD08C715988a3e8678745C84FC41a6, 1);
        _mint(0x55eF759C558592719D1345f1fAf56Af2f855d4F1, 1);
        _mint(0x9d73Aae64ec16aa0C85f0261E9A4529316D533f7, 1);
        _mint(0x5e6a905F64db6d3Bdb163434e48a56c005221ffd, 1);
        _mint(0x156f3116488ed4681C748C3eeEca4913FAfe4b82, 1);
        _mint(0x857e72Fbf579Aa99e981e4CEC3C7F291298Fe875, 1);
        _mint(0x8dc55615282096F8C1edDd9B20535B89f10cB23d, 1);
        _mint(0x1aECfa80D1057D09f78D0D5d9C77E10183719CcD, 1);
        _mint(0x7F30c38f84550817E8c7B22482e4a0FcF22198a4, 1);
        _mint(0xc4Bc19C1e49392EE0f4A87f9429a87633661f0dA, 1);
        _mint(0x589842381042ba2D242A2a22F17B2555E1338F5e, 1);
        _mint(0xc695D7097A6A4208b33cC7B85f8a6844a90977DD, 1);
        _mint(0x7DB12c0D617a8Ab8E199D13AAE351efad4741ED1, 1);
        _mint(0x0f9E037386a64056F7228212445E195c8d9A1699, 1);
        _mint(0x9c8D9490AFAB6fA03b8D9BaD0477f6a60bEe640c, 1);
        _mint(0xaaFb164259D27122530Aef535DCD059F5B3Dc844, 1);
        _mint(0x9b49d5b5D938D60F6852eE4ea493009381e9417F, 1);
        _mint(0x3C1B5e2258914B406f9d39f3EcBF3129318Dd933, 1);
        _mint(0x66d6a455Dfdde005cb7c18d56fDeB5567c93213F, 1);
        _mint(0xF7f37F5Cc8A875e7C9E26895c1Fa40cA5e7C15fd, 1);
        _mint(0x17C58eb7D11062690c68d00D9eBA45a92Ba3cE42, 1);
        _mint(0x22bFae7e253d778F355CF1Cb642B776a9914BBa8, 1);
        _mint(0xa0a7b66706b7f5c178AE49486a1C98B32670C038, 1);
        _mint(0xADCB78c30Ad01602fF3fB5b354382A1C4e7F40c7, 1);
        _mint(0xBc549b5dCcaECf61FA730a8eED485F84942eE224, 1);
        _mint(0xDb11B192249b414Aa6cc1e7F1d7414eCF59C36aF, 1);
        _mint(0x39e8a934fcf1eFb57AB0146ecD6c21aE019699A3, 1);
        _mint(0x7f1c7059799066214E1EC67A26C89560BcAE36b5, 1);
        _mint(0xfEBded7dF0b739564Dcb218B4e673f0918528B8d, 1);
        _mint(0x547aaa1BF305120aBB5c08F2697DE2A4CBAE46B1, 1);
        _mint(0x071fC12bE4EE6a484Fa42d3acE02209c4E1e3881, 1);
        _mint(0x995606723eCb1Cc2fe9a29FC29Dd509C07652622, 1);
        _mint(0x6B5e85DACC1f14137d74A22C3d2af711f2Deed8D, 1);
        _mint(0xa7d35E31CdDfC08339b7DE28450699A88d6F22Bc, 1);
        _mint(0x176b450a96AA8d8390224bBa76ac2BCd067ae643, 1);
        _mint(0xEC91Ca2d1f06f451EfD652A184a55b63C4667FF9, 1);
        _mint(0x700F99EBB1467fE47CD45d1faacb568761310BE4, 1);
        _mint(0x6D2fBF5873F36d949d2cb54a76Ef9F54A06abd7E, 1);
        _mint(0xf02692a0A1c848658F176286A8CbF75010a9090B, 1);
        _mint(0x000091892804f655cC1ACA5BBe42944dbb972aB1, 1);
        _mint(0xFE59F409d7A05f8e24aa90626186Cc820c8e3005, 1);
        _mint(0xfc7a999B74e62889366E97CBe799C1Bd11864D89, 1);
        _mint(0xC25317F5713E0CAc7B5d1a0b7b024AE4747cE0d1, 1);
        _mint(0x11f00D6C9116555b5Dd46f5E283750013ed7aa5E, 1);
        _mint(0xe4F4c76d44A3ac80dB8f08DF3F4EF76f1ab5c8bE, 1);
        _mint(0xf606507aE2E57C1c9CD67a0Afd2674160b5f3547, 1);
        _mint(0xAf9C6231eF8e5266443873aCCBabF5F05907Fb08, 1);
        _mint(0xc7F90cf9033bA51C166002A960bc276274bB7769, 1);
        _mint(0xA36B368523e9cF66C44AAf2Dc34c170f78B92683, 1);
        _mint(0x444fBF93192ae44640978b1199Ca981905Fd35De, 1);
        _mint(0xB8f6aB7B30CFf81d3B285a792b2917b35C885675, 1);
        _mint(0x73eA14C0439a6ECE889736a13cB200DA9f793002, 1);
        _mint(0x6a819E934D153b396e4b720da0864E8f0FF03505, 1);
        _mint(0x9363732e97315DE21A1F8e2874F89e0439014188, 1);
        _mint(0xbE79537a8c41676dB192D11Adbf0Beee25B35154, 1);
        _mint(0x62012BaFD7Ca21e0911Eeb8fABb4EEf4AE70107c, 1);
        _mint(0x419FbF18E4A0c6F626E819b877134FC1b2E4c928, 1);
        _mint(0xe59cD95759071d5A814Fcf163a957175160d4042, 1);
        _mint(0xA661019204cC6baD53feF5c60f4E13Ee8580683f, 1);
        _mint(0x0342A4198FC62C21B7fFD3505a7BF0Ab87110838, 1);
        _mint(0x3539e0f40c1EE32CD89bDa6725a3c492cB985D97, 1);
        _mint(0x91C4690Ce6fAab2B035D52408dCF597534437400, 1);
        _mint(0x075d846f46CA9A80491FD49AC31dF27c73af3FDA, 1);
        _mint(0x8F3C958430fbe692a820109a140041a786735488, 1);
        _mint(0x816734Db8BC22FE34D9E2BFc3f3D86e638C232DF, 1);
        _mint(0x3ee9F3B3458f95C9b5a76e840d45681C576532B3, 1);
        _mint(0xAb5313bcDbe72A7fF12cD3D5015C0Cb00F2D13fB, 1);
        _mint(0x42D77B54372bFd86fde5e947E3e3972f8Ab41BDb, 1);
        _mint(0xc13F8Ea701959c574fa6d80d1589a675400255D8, 1);
        _mint(0xDBC63fEd38D97E674CAbaAD8A34BE0B7D77f45fA, 1);
        _mint(0x64352672D5bBda44a576B2Fe886F23B109724124, 1);
        _mint(0x466E8ED99edF2019f1a39872bB7Be828b76619E4, 1);
        _mint(0x317921Cc525e50D264C89Cf0DF2e507DA997a85B, 1);
        _mint(0xd4acc964864CBc22BDD212A3D0FA330a150AB7c8, 1);
        _mint(0x646b719a937045596Da82E7D35F0C80f0a6373bA, 1);
        _mint(0x5fD8F613Be904b065E421F2e2f0FCb1A4f350559, 1);
        _mint(0x738D976BBfc63128Ef614755956A009aDF2b49B0, 1);
        _mint(0x6D1b48F1C7dE27Fe5F629Aad32A497729EC857F4, 1);
        _mint(0x73729767bAe0525F07904468848A717f7CB0b423, 1);
        _mint(0x5a12bc7150AF1faEe26271FE999386c5B0EC608c, 1);
        _mint(0x741ad4e94f05595625808dc0EAb127020A5A908A, 1);
        _mint(0x4eDa683542e0B8DDA2AeE225013Ba11Dcd5CDc8C, 1);
        _mint(0x90E6bCCf52FcBC7F835F5055404cE4A7bdE0b2E3, 1);
        _mint(0x3C1B5e2258914B406f9d39f3EcBF3129318Dd933, 1);
        _mint(0x72d57Cb1fbCc3fA8AAdf525a41fCC4B299d0b79d, 1);
        _mint(0x00349Ef28D79B6CFF1b683845aADa0Fb93222619, 1);
        _mint(0x7276bf87a5F9ab58189368e72F6e5056d239b300, 1);
        _mint(0x7475aee718b78d82817906d7F5C700E64E508106, 1);
        _mint(0xdDc1006Adb7a56DC671E06A813e7C831ea1B3d90, 33);
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // return "https://ipfs.io/ipfs/QmYmV1njXt1VnbEy3N1GFNp8P9sMATsa2JK7uGy5cRJA7w";
        return magma_uri;
    }   

    function changeUri(string memory _new_uri) external onlyOwner {
        magma_uri = _new_uri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function isWhitelisted(address _user, bytes32 [] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verifyCalldata(_merkleProof, merkle_root, leaf);
    }

    function getNumClaimed(address _user) public view returns(uint64) {
        return _getAux(_user);
    }
    
    function whitelistMint(bytes32 [] calldata _merkleProof) external payable {
        require(tx.origin == msg.sender);
        require(private_sale_running, "Private sale is not running");
        require(msg.value == MINT_PRICE, "Incorrect ETH sent to mint");
        require(_totalMinted() < MAX_SUPPLY, "Not enough tokens left to mint");

        require(isWhitelisted(msg.sender, _merkleProof), "Invalid proof");

        uint64 num_claimed = _getAux(msg.sender);
        require(num_claimed == 0, "You can only claim 1 token");

        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function burn(uint _token_id) external {
        _burn(_token_id, true);
    }

    function togglePrivateSale() external onlyOwner {
        private_sale_running = !private_sale_running;
    }

    function adminMint(address _destination, uint _quantity) external onlyOwner {
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Not enough tokens left to mint");
        _mint(_destination, _quantity);
    }

    function updateWhitelistMerkleRoot(bytes32 _new_root) external onlyOwner {
        merkle_root = _new_root;
    }

    function updateMintingPrice(uint _new_price) external onlyOwner {
        MINT_PRICE = _new_price;
    }
    
    function withdraw() external onlyOwner {
        payable(0x3799Ee1cD01A61Bcded7fEb949168D3dAb29Cf99).transfer(address(this).balance);
    }
}