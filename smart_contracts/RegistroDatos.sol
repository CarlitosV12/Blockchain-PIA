// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RegistroDatosProyecto
 * @dev Contrato 
 */
contract RegistroDatosProyecto {

    // 1. Variables de Estado obligatorias
    address public administrador;
    uint256 public costoRegistro;

    // Estructura y mapeo para guardar la información por usuario
    struct Registro {
        string informacion;
        bool existe;
    }

    mapping(address => Registro) public registros;

    // Eventos de trazabilidad
    event DatoRegistrado(address indexed usuario, string informacion, uint256 pago);
    event DatoLimpiado(address indexed usuarioAfectado);

    // Modificador de permisos con require usando la variable 'administrador'
    modifier soloAdministrador() {
        require(msg.sender == administrador, "Acceso denegado: Solo el administrador puede realizar esta accion.");
        _;
    }

    // Constructor que asigna al creador como administrador y define un costo inicial (ej. 0.01 ETH)
    constructor(uint256 _costoInicial) {
        administrador = msg.sender;
        costoRegistro = _costoInicial;
    }

    // 2. Función estrella: Recibe pago en criptomonedas (payable)
    function registrarDato(string memory _informacion) public payable {
        require(msg.value >= costoRegistro, "Pago insuficiente: envia el costo de registro requerido.");
        require(bytes(_informacion).length > 0, "La informacion no puede estar vacia.");

        registros[msg.sender] = Registro({
            informacion: _informacion,
            existe: true
        });

        emit DatoRegistrado(msg.sender, _informacion, msg.value);
    }

    // 3. Función de lectura gratuita (view)
    function leerDato(address _usuario) public view returns (string memory) {
        require(registros[_usuario].existe, "El usuario especificado no tiene registros guardados.");
        return registros[_usuario].informacion;
    }

    // 4. Función de limpieza restringida al administrador con require
    function limpiarRegistro(address _usuario) public soloAdministrador {
        require(registros[_usuario].existe, "El usuario no cuenta con un registro activo para limpiar.");
        
        delete registros[_usuario];

        emit DatoLimpiado(_usuario);
    }

    // Función extra para retirar los fondos acumulados por los pagos
    function retirarFondos() public soloAdministrador {
        uint256 saldo = address(this).balance;
        require(saldo > 0, "No hay fondos para retirar.");
        
        (bool success, ) = payable(administrador).call{value: saldo}("");
        require(success, "Fallo la transferencia de fondos.");
    }
}
