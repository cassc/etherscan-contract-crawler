// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// Opensea: represents a proxy contract of a user
contract OwnableDelegateProxy {}

/**
 Opensea:
 This represents Opensea's ProxyRegistry contract.
 We use it to find and approve the opensea proxy contract of a 
 user so our contract is better integrated with opensea.
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MechanizedAbstractions is AccessControl, Ownable, ERC721, VRFConsumerBase {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    // Addresses
    address public proxyRegistryAddress; // Opensea: the address of the Opensea ProxyRegistry 

    // Strings
    string public p5ScriptArweaveAddress; // points to the p5 script on arweave https://55mcex7dtd5xf4c627v6hadwoq6lgw6jr4oeacqd5k2mazhunejq.arweave.net/71giX-OY-3LwXtfr44B2dDyzW8mPHEAKA-q0wGT0aRM
    string public baseURIString = "";   // represents the baseURI of the metadata
    string public p5script = "function mechanizedAbstractionRenderer(e){let[t,o]=function(e){const t=parseInt(e.slice(0,Math.floor(e.length/2)))%1e10,o=parseInt(e.slice(Math.floor(e.length/2),e.length))%1e10;return[t,o]}(e);var l,n,r,a,F,d,i,s,v,D,A,h=60,E=255,B={};let b={},c={'Mid-century':{v:['#F1B680','#E98355','#D24227','#274274','#4787A8','#89B6AB','#8AAAA2'],w:7,bbl:['#D24227','#F1B680','#E98355']},Unpacked:{v:['#00000B','#87F8DF','#DE4338','#F4C0D9','#2E34C5','#E7E96D'],w:7,bbl:[]},Boardwalk:{v:['#B8E2D3','#5B9AF5','#FD2B73','#FE8233','#D40C0C','#FFCA35','#1F7340','#0343C1','#66093E'],w:3,bbl:['#5B9AF5','#FE8233','#D40C0C','#FFCA35','#1F7340','#0343C1','#66093E']},'Pop!':{v:['#E7147F','#179AED','#2C2A87','#F4EF19','#7A4A95','#9DD340','#DC132A'],w:6,bbl:['#DC132A','#']},Sunburst:{v:['#143642','#ec9a29','#0f8b8d','#dad2d8'],w:3,bbl:[]},Ethereal:{v:['#03B87A','#6139D0','#60A0F4','#FFDE3A','#F4FCFF','#2A2F4D','#F6C1FF'],w:7,bbl:['#FFDE3A','#F6C1FF']},Coral:{v:['#FF8A71','#DB82A8','#55BCF5','#7CD3C5','#0246C9','#FFBAAB'],w:5,bbl:[]},Paradise:{v:['#FD9672','#FAA34F','#6BACB5','#3F7088','#EDC1BE'],w:4,bbl:['#FD9672','#FAA34F']},'Ultra Red':{v:['#313B42','#FFEEE4','#E54F2D','#FD7A6E','#FFBDB7'],w:4,bbl:['#E54F2D','']},'Ocean Blues':{v:['#3073AD','#78B0E2','#9CC2E3','#D9EDFF','#0788D9'],w:2,bbl:['#D94F30']},Dreamscape:{v:['#E0CEFA','#88A0E4','#5991FF','#FFA794','#FF8282','#B9FDDD'],w:5,bbl:['#FFA794','#FF8282']},Blossom:{v:['#2A764B','#55A578','#F5F5D9','#FFC4B2','#DC934C'],w:3,bbl:['','','']},Mystique:{v:['#A57AFF','#C4F500','#03CCBF','#80FFD4','#03A0FF','#0469A6','#30337A'],w:5,bbl:['#03A0FF','#C4F500']},Nautical:{v:['#FAC998','#EB9C44','#D9492A','#A12425','#347D95'],w:4,bbl:['#D9492A','#EB9C44']},Retro:{v:['#F4EE97','#F9D74D','#EC9E43','#E2693C','#4A6076'],w:2,bbl:['#','#']},'Ode to Van Gogh':{v:['#2A4184','#5A87C2','#94C0D2','#EFE986','#1B2424'],w:3,bbl:['#EFE986']},'Ode to Mondrian':{v:['#D2BA49','#B7B8B2','#143675','#9E2F2A','#DDDDD9'],w:3,bbl:['#9E2F2A','#143675']},'Ode to Monet':{v:['#C4C7BA','#344147','#6A8993','#D46E60','#D18D74'],w:3,bbl:['#D46E60']},'Midnight Blue':{v:['#000421','#1BC5D2'],w:2,bbl:['#1BC5D2']},Monochrome:{v:['#F0EFEF','#373737'],w:2},Punkable:{v:['#6C91A6','#D77247','#CBEDEC','#FFF0B5','#313131','#9BC989','#BEBEBE'],w:3,bbl:['#D77247']},Apeable:{v:['#9A9B6B','#B9CBDC','#F3B468','#396785','#74D4B4','#9979A0','#F2F29C'],w:3,bbl:['#ED041F']}},w={Solid:{v:'solid',w:80},Translucent:{v:'translucent',w:20}},m={Low:{v:{mean:15,std:5,floor:20},w:60},Medium:{v:{mean:30,std:5,floor:20},w:20},High:{v:{mean:40,std:5,floor:20},w:10}},C={None:{v:0,w:89},Thick:{v:1.5,w:10},Thin:{v:1,w:1}},u={White:{v:'rgba(255,255,255,.8)',w:1},Black:{v:'rgba(0,0,0,.6)',w:1}},f={Short:{v:{mean:200,std:150},w:1},Normal:{v:{mean:400,std:300},w:1},Long:{v:{mean:1500,std:250},w:1}},g={Thin:{v:{mean:3,std:.1},w:25},Normal:{v:{mean:10,std:5},w:60},Thick:{v:{mean:20,std:5},w:15}},p={Normal:{v:2e-4,w:85},Straight:{v:1e-6,w:15}},k={Normal:{v:{mean:25e3,std:25e3},w:1},None:{v:{mean:0,std:0},w:1}},M={'No Border':{v:-25,w:85},Border:{v:35,w:15}};var S=function(e,t){var o=Object.keys(e),l=[];for(let t=0;t<o.length;t++){let n=e[o[t]].w;for(let e=0;e<n;e++)l.push(o[t])}return l[t.floor(t.random()*l.length)]};function y(e,t,o,l){let n=e.randomGaussian(2,10);var r=[],a=[];for(var F=0;F<13;F++){let l=n+e.random(-n/35,n/35);r[F]=t+l*e.cos(360*F/13),a[F]=o+l*e.sin(360*F/13)}e.beginShape();for(let t=0;t<r.length;t++)e.curveVertex(r[t],a[t]);e.endShape(e.CLOSE)}function x(e,t,o){let l=o.randomGaussian(D,10);return e<l||e>o.width-l||t<l||t>o.height-l}function N(e,t,o){let l=e.randomGaussian(i.mean,i.std),n=e.randomGaussian(s.mean,s.std);var r=[],F=[];r.push(t);for(let t=0;t<l;t++){let o=e.createVector(r[t].x+n,r[t].y+n);if(x(r[t].x+n,r[t].y+n,e))--t,--l;else{F.push(o);var v=e.map(e.noise(r[t].x*d,r[t].y*d),0,1,0,720);if(x(r[t].x+e.cos(v),r[t].y+e.sin(v),e))--t,--l;else{var D=e.createVector(r[t].x+e.cos(v),r[t].y+e.sin(v));r.push(D)}}}for(e.beginShape(),t=0;t<r.length;t++){let o=r[t];e.vertex(o.x,o.y)}for(t=F.length-1;t>=0;t--){let o=F[t];e.vertex(o.x,o.y)}e.endShape(),e.stroke(a);let A=e.color(o);A.setAlpha(E),e.fill(A)}return{renderer:e=>{e.setup=function(){e.randomSeed(t),e.noiseSeed(o);let x=e.createCanvas(1500,500);var G;for(e.angleMode(e.DEGREES),function(e){B.randomSeed=t,B.noiseSeed=o;let v=S(w,e);B['fill type']=v,'translucent'==w[v].v&&(delete c.Monochrome,delete c['Midnight Blue'],delete C.Thick,delete m.Low,delete m.Medium,h=80,E=200);let b=S(M,e);B.borderStyle=b,(D=M[b].v)>0&&(delete m.Low,delete m.Medium);let y=S(m,e);B.density=y,F=m[y].v;let x=S(c,e);B.colors=x,l=c[x].v,n=c[x].bbl,'Midnight Blue'==x&&(delete u.Black,delete C.None,delete C.Thick),'Monochrome'==x&&(delete u.White,delete C.None,delete C.Thick);let N=S(C,e);B.strokeThickness=N,r=C[N].v;let G=S(u,e);B.strokeColor=G,a=u[G].v;let T=S(f,e);B.curveLength=T,i=f[T].v;let L=S(g,e);B.curveWidth=L,s=g[L].v;let O=S(p,e);B.curveRate=O,d=p[O].v;let R=S(k,e);B.textureDensity=R,A=k[R].v}(e);null==G;){let t=l[e.floor(e.random()*l.length)];null!=n&&n.includes(t)||(G=t)}e.background(G),l=l.filter(e=>e!=G),e.strokeWeight(r);let T=e.floor(e.max(e.randomGaussian(F.mean,F.std),F.floor));for(var L=e.width/T,O=D;O<e.width-D;O+=L)for(var R=D;R<e.height-D;R+=L)if(e.floor(100*e.random())<=h){var U=e.createVector(O+e.random(-10,10),R+e.random(-10,10));N(e,U,l[e.floor(e.random()*l.length)])}else e.random(),e.width,e.random(),e.height,y(e,O+e.randomGaussian(20,20),R+e.random(20,20),l[e.floor(e.random()*l.length)]);v=e.randomGaussian(A.mean,A.std),function(e,t){let o=e.floor(e.random(50,90)),l=e.color(20,20,20,o);e.noStroke(),e.fill(l);for(let o=0;o<t;o++){let t=e.random()*e.width,o=e.random()*e.height,l=e.random(0,1.5);e.ellipse(t,o,l)}}(e,v),b.dataUrl=x.canvas.toDataURL()},e.draw=function(){e.noLoop()}},properties:B,dataUrl:b}}";
    string public arweaveGateway = "https://arweave.net/";

    // Flags
    bool public isContractOpen = true;

    // Token data 
    uint256 public nextTokenId = 1;  

    /** ROLES */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Arweave metadata
    uint256[] public arweaveManifestBatches; // excluding the token of the value itself
    string[] public  arweaveManifestIds;

    // Chainlink VRF variables
    bytes32 private keyHash; // public key used to generate random values
    uint256 private fee; // fee paid to chainlink node for random value
    uint256 public baseSeed = 0;

    // MechanizedAbstractions seed values
    mapping(uint256 => uint256) private _vrfValues;
    mapping(uint256 => uint256) public seedValues; // maps token id to seed value

    // events
    event Minted(address minter, uint256 tokenId);
    event VRFRequested(bytes32 requestId);
    event VRFReceived(bytes32 requestId);
    event ReceivedEther(uint256 amount, address _from);

    // modifiers
    modifier modifiable {
        require(isContractOpen, "NOT MODIFIABLE");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _p5ScriptArweaveAddress,
        address _vrfCoordinator,
        address _linkTokenAddress,
        uint256 _vrfFee,
        bytes32 _keyHash
    ) Ownable() ERC721(_name, _symbol) VRFConsumerBase(
        _vrfCoordinator,
        _linkTokenAddress
    ) {
        proxyRegistryAddress = _proxyRegistryAddress; // set the provided ProxyRegistry address to our own state variable
        p5ScriptArweaveAddress = _p5ScriptArweaveAddress; // set arweave address of p5 script
        keyHash = _keyHash; // set the keyhash used for rng
        fee = _vrfFee; // fee paid to chainlink VRF node, varies per network (0.1 * 10 ** 18) = 0.1 link

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }    

    /** === ERC-721 & METADATA functions === */
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
    * @dev returns the baseURI for the metadata. Used by the tokenURI method.
    * @return the URI of the metadata
    */
    function _baseURI() internal override view returns (string memory) {
        return baseURIString;
    }

    /**
     * @dev returns the tokenUri of a token
     * First it checks if the token exists, if not it reverts
     * Then it tries to find the batch index of the token
     * If the batch index is not found it returns a link to the server
     * Otherwise it returns a link to the corresponding arweave manifest
     *
     * @param tokenId the tokenId of the token
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TOKEN DOESN'T EXIST");

        // Look for the arweave batch index of the token
        uint256 index = 0;
        bool found = false;
        for (uint i = 0; i < arweaveManifestBatches.length; i++) {
            if (tokenId < arweaveManifestBatches[i]) {
                index = i;
                found = true;
                break;
            }
        }

        // If no arweave manifest was uploaded for tokenId return a link to the server
        if (!found) {
            return string(abi.encodePacked(_baseURI(), tokenId.toString()));
        }

        // Otherwise return the arweave link
        return string(abi.encodePacked(arweaveGateway, arweaveManifestIds[index], "/", tokenId.toString()));
    }

    /** === ONLY OWNER === */

    /**
     * @dev Allows the signatureProvider to set a new manifestId
     * for a given batch.
     *
     * @param batchId the batch Id
     * @param manifestId the manifest Id
     */
    function setArweaveManifestId(uint256 batchId, string memory manifestId) external onlyOwner {
        if (arweaveManifestBatches.length > 0) {
            require(arweaveManifestBatches[arweaveManifestBatches.length - 1] < batchId, "BATCH ID SHOULD EXCEED PREVIOUS ONE");
        }

        arweaveManifestBatches.push(batchId);
        arweaveManifestIds.push(manifestId);
    }

    function resetArweave() external onlyOwner modifiable {
        delete arweaveManifestBatches;
        delete arweaveManifestIds;
    }

    function setP5(string calldata _p5) external onlyOwner modifiable {
        p5script = _p5;
    }

    function setP5Address(string calldata _address) external onlyOwner modifiable {
        p5ScriptArweaveAddress = _address;
    }

    /**
    * @dev function to change the baseURI of the metadata
    */
    function setBaseURI(string memory _newBaseURI) public onlyOwner modifiable {
        baseURIString = _newBaseURI;
    }

    function setArweaveGateway(string calldata _gateway) external onlyOwner modifiable {
        arweaveGateway = _gateway;
    }

    /**
     * @dev Allows the owner to withdraw link
     */
    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "LINK Transfer failed");
    }

    /**
     * @dev Allows the owner to withdraw ether
     */
    function withdrawEth() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH Transfer failed");
    }

    function disableModifications() external onlyOwner {
        isContractOpen = false;
    }

    /** === OPENSEA FUNCTIONS === */

    /**
    * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Create an instance of the ProxyRegistry contract from Opensea
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        // whitelist the ProxyContract of the owner of the NFT
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /** === MINT METHODS === */

    /**
     * @dev mints numberOfTokens tokens.
     * - A new VRF request is made before each 15 tokens are minted
     * - Creates a new tokenData struct
     * - Increments the tokenId
     * - Checks if the VRF value for this batch is ready
     * - If so it mints the token
     * - If not it adds to token to pending mints array for current requestId
     * - And it adds one to the pending mints of the users
     * 
     * @param numberOfTokens the number of tokens to mint
     */
    function doMint(uint256 numberOfTokens, address _to) external onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < numberOfTokens; i++) {       

            _safeMint(_to, nextTokenId); 
            seedValues[nextTokenId] = (uint256(keccak256(abi.encode(nextTokenId, baseSeed, msg.sender, block.timestamp, blockhash(block.number)))));

            emit Minted(_to, nextTokenId); 
            nextTokenId = nextTokenId.add(1);
        }
    }

    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    /** === CHAINLINK VRF METHODS === */

    /** 
     * Requests randomness 
     */
    function _requestNewVRN() external onlyOwner modifiable returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= fee, "NOT ENOUGH LINK");
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit VRFRequested(requestId);
        return requestId;
    }

    /**
     * @dev Callback function used by VRF Coordinator
     * Pushed new VRF value to array
     * Mints any pending tokens
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        baseSeed = randomness;
        emit VRFReceived(requestId);
    }

    /** === MISC === */
    
    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.value, msg.sender);
    }        

    /**
     * @dev returns the amount fo arweave batches that have been uploaded
     */
     function arweaveBatchLength() external view returns(uint256) {
         return arweaveManifestBatches.length;
     }
}