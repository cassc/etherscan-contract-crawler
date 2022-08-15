pragma solidity ^0.8.3;
//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Lightrays is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for string;
    uint public constant MAX = 100;
    uint public constant price = 125000000000000000;
    bool public pause = true;
    address public payableAddress = 0x393eADB8CC8873b01F2ef07C371211bd60B4da3F;
    string public baseURI = "https://api.cooperjamieson.com/lightrays/";
 
    constructor() ERC721("Lightrays", "LTR") {
        _safeMint(payableAddress, 0);
        _safeMint(payableAddress, 1);
        _safeMint(payableAddress, 2);
        _safeMint(payableAddress, 3);
        _safeMint(payableAddress, 4);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

   function purchase() public payable {
        require(pause == false, "Sale has not started.");
        require(totalSupply() < MAX, "All artworks have sold.");
        require(msg.value >= price, "Need higher ether value.");
        require(msg.value <= price, "You are overpaying.");

        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        payable(address(payableAddress)).transfer(125000000000000000);
    }

    function changePayableAddresses(address _address) public onlyOwner {
        payableAddress = _address;
    }

    function baseTokenURI() internal view returns (string memory) {
        return baseURI;
    }

    function append1(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return append1(baseTokenURI(), Strings.toString(_tokenId),".json");
    }
    
    function pauseMint() public onlyOwner {
        pause = true;
    }

    function unpauseMint() public onlyOwner {
        pause = false;
    }

    function append2(uint256 _tokenId) internal pure returns (string memory) {
        if (_tokenId > 99 || _tokenId < 0) {
            return "Invalid tokenId";
        } else {            
            string memory c = "U = 'Color';T = False;S = 'Damped Track';R = 'Empty';N = 'Array.002';M = 'Array.001';L = 'ARRAY';K = 'Material';J = 'OBJECT';I = 'EDIT';F = 'Cube';E = 'DESELECT';D = 'Material.001';C = 'Principled BSDF';B = True;f = 'Empty';e = 'Camera';b = round;import bpy as A, random as a;A.context.scene.render.engine = 'CYCLES';A.context.scene.cycles.feature_set = 'SUPPORTED';A.context.scene.cycles.samples = 80;A.context.scene.cycles.use_adaptive_sampling = B;A.context.scene.render.resolution_x = 2400;A.context.scene.render.resolution_y = 2400;A.context.scene.frame_start = 1;A.context.scene.frame_end = 1;A.ops.object.select_all(action = E);A.data.objects['Light'].select_set(B);A.ops.object.delete();A.ops.object.select_all(action = E);O = A.data.objects.new(R, None);A.context.scene.collection.objects.link(O);A.ops.object.select_all(action = E);A.context.view_layer.objects.active = A.data.objects[e];A.ops.object.constraint_add(type = 'DAMPED_TRACK');A.context.object.constraints[S].target = A.data.objects[R];A.context.object.constraints[S].track_axis = 'TRACK_NEGATIVE_Z';A.ops.object.select_all(action = E);A.context.view_layer.objects.active = A.data.objects[F];A.data.objects[F].select_set(B);A.ops.object.modifier_add(type = L);A.context.object.modifiers['Array'].count = 5;A.ops.object.modifier_add(type = L);A.context.object.modifiers[M].relative_offset_displace[0] = 0;A.context.object.modifiers[M].relative_offset_displace[1] = 1;A.context.object.modifiers[M].count = 5;A.ops.object.modifier_add(type = L);A.context.object.modifiers[N].relative_offset_displace[0] = 0;A.context.object.modifiers[N].relative_offset_displace[2] = 1;A.context.object.modifiers[N].count = 5;A.data.objects[F].location[0] = -4;A.data.objects[F].location[1] = -4;A.data.objects[F].location[2] = -4;A.ops.object.mode_set(mode = I);A.ops.mesh.subdivide(number_cuts = 2);A.ops.mesh.select_all(action = E);A.ops.mesh.select_mode(use_extend = T, use_expand = T, type = 'FACE');A.ops.object.mode_set(mode = J);A.context.active_object.data.polygons[11].select = B;A.context.active_object.data.polygons[19].select = B;A.context.active_object.data.polygons[27].select = B;A.context.active_object.data.polygons[35].select = B;A.context.active_object.data.polygons[43].select = B;A.context.active_object.data.polygons[51].select = B;A.ops.object.mode_set(mode = I);A.ops.object.material_slot_assign();A.ops.object.mode_set(mode = J);A.data.materials[K].node_tree.nodes[C].inputs[9].default_value = 1;A.data.materials[K].node_tree.nodes[C].inputs[17].default_value = 1;A.data.materials[K].node_tree.nodes[C].inputs[0].default_value = 0, 0, 0, 1;A.data.materials[K].node_tree.nodes[C].inputs[21].default_value = 0.5;A.ops.object.mode_set(mode = I);A.ops.mesh.select_all(action = 'INVERT');A.ops.object.mode_set(mode = J);A.ops.object.material_slot_add();A.context.active_object.data.materials[1] = A.data.materials.new(name = D);A.data.materials[D].use_nodes = B;A.ops.object.mode_set(mode = I);A.ops.object.material_slot_assign();A.ops.object.mode_set(mode = J);A.data.materials[D].node_tree.nodes[C].inputs[9].default_value = 0;A.data.materials[D].node_tree.nodes[C].inputs[17].default_value = 1;A.data.materials[D].node_tree.nodes[C].inputs[0].default_value = 1, 1, 1, 1;A.data.materials[D].node_tree.nodes[C].inputs[21].default_value = 0.1;G = A.data.worlds[A.context.scene.world.name].node_tree.nodes.new(type = 'ShaderNodeTexSky');H = A.data.worlds[A.context.scene.world.name].node_tree.nodes['Background'];G.location.x = H.location.x - 300;G.location.y = H.location.y;P = G.outputs[U];Q = H.inputs[U];A.data.worlds[A.context.scene.world.name].node_tree.links.new(P, Q);a.seed(";
            string memory d = Strings.toString(_tokenId);
            string memory e = ");DD = A.data.worlds['World'].node_tree.nodes['Sky Texture'];A.data.objects[f].location[0] = b(a.uniform(-3, 3), 5);A.data.objects[f].location[1] = b(a.uniform(-3, 3), 5);A.data.objects[f].location[2] = b(a.uniform(-3, 3), 5);A.data.objects[e].location[0] = b(a.uniform(-10, 10), 5);A.data.objects[e].location[1] = b(a.uniform(-10, 10), 5);A.data.objects[e].location[2] = b(a.uniform(-10, 10), 5);A.data.objects[e].data.dof.use_dof = True;A.data.objects[e].data.dof.focus_distance = b(a.uniform(1, 12), 5);A.data.objects[e].data.dof.aperture_fstop = b(a.uniform(.05, 8), 5);A.data.objects[e].data.lens = b(a.uniform(40, 90), 0);DD.sun_elevation = b(a.uniform(0, 5), 5);DD.sun_size = b(a.uniform(.001, 0.07), 5);DD.sun_intensity = b(a.uniform(.01, 3), 5);DD.sun_rotation = b(a.uniform(0, 6.28319), 5);DD.altitude = b(a.uniform(0, 55), 5);DD.air_density = b(a.uniform(0, 4), 5);DD.dust_density = b(a.uniform(0, 10), 5);DD.ozone_density = b(a.uniform(0, 3), 5);";
            return string(abi.encodePacked(c,d,e)); 
        }  
    }

    function projectDetails(uint256 _tokenId) pure public returns (string memory projectName, string memory artist, string memory description, string memory website, string memory license, string memory getRenderer, string memory getTokenScript) {
        projectName = "Light Rays";
        artist = "Cooper Jamieson";
        description = "This series explores the seemingly infinite number of ways that light interacts with translucent materials and is a meditation on how light alters form. Code used to produce the outputs are stored on the Ethereum blockchain. This work is open-source and CC0. Please use these contracts to create your own artworks.";
        website = "https://www.cooperjamieson.com/lightrays";
        license = "CC0";
        getRenderer = "Blender 3.0.1";
        getTokenScript = append2(_tokenId);
    }
}