-- Base type
type File = {
    Name: string,
    Start: () -> (),
    Init: () -> (),
}

export type Service = {
    Name: string,
    Shared: boolean,
}

export type Controller = {
    Priority: number,
}

export type Manager = File & {
    Priority: number,
}

export type Packet = {
    Recieve: any,
    Data: any,
}

return nil