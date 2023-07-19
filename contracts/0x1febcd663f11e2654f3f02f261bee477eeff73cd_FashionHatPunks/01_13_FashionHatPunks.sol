pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "base64-sol/base64.sol";
import "./ERC721r.sol";

interface HatPunkData {
    function punkAttributesAsJSON(uint16 punkId, uint16 punkSeed) external view returns (string memory);
}

interface HatPunkRenderer {
    function punkImageSvg (uint16 punkId, uint16 punkSeed, uint32 backgroundColor, bool phunkify) external view returns ( string memory svg );
}

contract FashionHatPunks is Ownable, ERC721r {
    using Address for address;
    using Strings for uint16;
    using Strings for uint8;
    using Strings for uint256;
    
    HatPunkData public hatDataContract;
    HatPunkRenderer public hatRendererContract;
    
    bool public contractSealed;
    bool public isMintActive;
    
    uint32 public backgroundColor = 2693432063;
    mapping (uint16 => uint16) public punkSeeds;
    
    mapping(address => uint) private freeMintsForWallet;
    uint public maxMintsPerTransaction = 300;
    
    string private tokenDescriptionJSON = 'One of 10,000 unique Punks from the Fashion Hat Punk collection, the world\xE2\x80\x99s first hat-centric 100% on-chain CryptoPunk derivative.\\n\\nIf you\xE2\x80\x99re looking for an uncensorable on-chain Punk who loves fashion, hates implied affiliation, loves being unique, and hates external dependencies, you\xE2\x80\x99re in the right place!';
    
    string private contractDescriptionJSON = "Fashion Hat Punks are an on-chain PFP collection that invites us to imagine a world in which all 10,000 CryptoPunks wore fashionable hats that were added on-chain without any duplicates.\\n\\nNo external dependencies, no implied affiliation with any brand, just Punks whose fashion sense can never be censored and will never go out of style.";
    
    string private contractExternalLink = "https://fashionhatpunks.com";
    
    uint16 contractImagePunkId = 7804;
    
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external onlyOwner unsealed {
        contractSealed = true;
    }
    
    constructor(uint16[][] memory _punkSeeds) ERC721r("Fashion Hat Punks", "HATPUNK", 10_000) {
        setPunkSeeds(_punkSeeds);
    }
    
    function setPunkSeeds(uint16[][] memory _punkSeeds) public onlyOwner unsealed {
        for (uint i; i < _punkSeeds.length; i++) {
            uint16 id = _punkSeeds[i][0];
            uint16 seed = _punkSeeds[i][1];
            punkSeeds[id] = seed;
        }
    }
    
    function setHelperContracts(address hatDataAddress, address hatRendererAddress) external onlyOwner unsealed {
        hatDataContract = HatPunkData(hatDataAddress);
        hatRendererContract = HatPunkRenderer(hatRendererAddress);
    }
    
    function setBackgroundColor(uint32 _backgroundColor) external onlyOwner unsealed {
        backgroundColor = _backgroundColor;
    }
    
    function setTokenDescription(string memory _tokenDescription) external onlyOwner unsealed {
        tokenDescriptionJSON = _tokenDescription;
    }
    
    function setContractDescription(string memory _contractDescription) external onlyOwner unsealed {
        contractDescriptionJSON = _contractDescription;
    }
    
    function setExternalLink(string memory _externalLink) external onlyOwner unsealed {
        contractExternalLink = _externalLink;
    }
    
    function setContractImagePunkId(uint16 _contractImagePunkId) external onlyOwner unsealed {
        contractImagePunkId = _contractImagePunkId;
    }
    
    function setMaxMintsPerTransaction(uint _maxMintsPerTransaction) external onlyOwner {
        maxMintsPerTransaction = _maxMintsPerTransaction;
    }
    
    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }
    
    function mintFashionHatPunk(address toAddress, uint numTokens) public payable {
        require(isMintActive, "Mint is not active");
        require(!_msgSender().isContract(), "Contracts cannot mint");
        
        require(numTokens <= maxMintsPerTransaction, "Can't mint that many");
        require(msg.value == totalMintCost(numTokens, _msgSender()), "Need exact payment");
        
        if (freeMintsForWallet[_msgSender()] > 0) {
            uint toSubtract = Math.min(freeMintsForWallet[_msgSender()], numTokens);
            freeMintsForWallet[_msgSender()] -= toSubtract;
        }
        
        _mintRandom(toAddress, numTokens);
    }
    
    function tokenSVG(uint16 id) public view returns (string memory) {
        return hatRendererContract.punkImageSvg(id, punkSeeds[id], backgroundColor, false);
    }
    
    function tokenAttributes(uint16 id) public view returns (string memory) {
        return hatDataContract.punkAttributesAsJSON(id, punkSeeds[id]);
    }
    
    function constructTokenURI(uint16 id) private view returns (string memory) {
        string memory _punkSVG = Base64.encode(bytes(tokenSVG(id)));
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                'Fashion Hat Punk #', id.toString(),
                                '", "description": "',
                                tokenDescriptionJSON,
                                '", "attributes": ',
                                tokenAttributes(id),
                                ', "image_data": "',
                                "data:image/svg+xml;base64,",
                                _punkSVG,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        return constructTokenURI(uint16(id));
    }
    
    function contractURI() external view returns (string memory) {
        string memory contractSVG = Base64.encode(bytes(tokenSVG(contractImagePunkId)));
        
        contractSVG = string(abi.encodePacked("data:image/svg+xml;base64,", contractSVG));
        
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', name(), '",'
                                '"description":"', contractDescriptionJSON, '",'
                                '"image_data":"', contractSVG, '",'
                                '"external_link":"', contractExternalLink, '"'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function walletOfOwner(address _owner)
        external
        view
        returns (uint[] memory)
    {
        uint ownerTokenCount = balanceOf(_owner);
        uint[] memory ownedTokenIds = new uint[](ownerTokenCount);
        uint currentTokenId = 0;
        uint ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply()) {
            address currentTokenOwner = _exists(currentTokenId) ? ownerOf(currentTokenId) : address(0);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }
    
    function mintedTokenIds() external view returns (uint[] memory) {
        uint tokenCount = totalSupply();
        uint[] memory mintedTokenIdsResult = new uint[](tokenCount);
        uint currentTokenId = 0;
        uint mintedTokenIndex = 0;
        
        while (mintedTokenIndex < tokenCount && currentTokenId < maxSupply()) {
            if (_exists(currentTokenId)) {
                mintedTokenIdsResult[mintedTokenIndex] = currentTokenId;

                mintedTokenIndex++;
            }
            
            currentTokenId++;
        }
        
        return mintedTokenIdsResult;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
    
    function updateFreeMintsForWallet(address wallet, uint newFreeMintCount) external onlyOwner {
        freeMintsForWallet[wallet] = newFreeMintCount;
    }
    
    function totalMintCost(uint numTokens, address minter) public view returns (uint) {
        if (numTokens == 0 || minter == owner()) {
            return 0;
        }
        
        int paidMints = int(numTokens) - int(freeMintsForWallet[minter]);
        
        if (paidMints < 0) {
            paidMints = 0;
        }
        
        uint costPerMint = paidMints >= 10 ? 0.01 ether : 0.02 ether;
        
        return uint(paidMints) * costPerMint;
    }
}