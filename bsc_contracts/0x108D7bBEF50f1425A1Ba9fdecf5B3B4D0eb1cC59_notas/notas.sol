/**
 *Submitted for verification at BscScan.com on 2022-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.1 < 0.7.0;


contract notas {

    address public profesor;

    // Constructor para establecer el address profesor al que ejecuta elo contrato 
    constructor() public {
        profesor = msg.sender;
    }

    // Mapping para relacionar el hash de la identidad del alumno con su nota de exament
    mapping (bytes32 => uint) Notas;

    // Array de los alumnos que pidan revisiones de examen
    string [] revisiones;

    // Eventos 
    event alumno_evaluado(bytes32, uint);
    event evento_revision(string);

    //Función para evaluar a alumnos
    function Evaluar(string memory _idAlumno, uint _nota) public UnicamenteProfesor(msg.sender){

        // Hash de la identificación del alumno
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        // Realación del hash del alumno y su nota
        Notas[hash_idAlumno] = _nota;
        // Emitir evento
        emit alumno_evaluado(hash_idAlumno, _nota);

    }

    modifier UnicamenteProfesor(address _direccion){
        //Requiera que la dirección introducida sea igual al propietario del contrato
        require(_direccion == profesor, "No tienes persmisos para ejecutar esta función");
        _;
    }

    //Función para ver notas del alumno
    function VerNotas(string memory _idAlumno) public view returns(uint){
        // Hash de la identificación del alumno
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        // Nota asociada al hash del alumno
        uint nota_alumno = Notas[hash_idAlumno];
        // Visualizar la nota 
        return nota_alumno;

    }

}