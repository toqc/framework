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

export type Controller = File & {
	Priority: number,
}

export type Manager = File & {
	Priority: number,
}

export type Utility = {any: any}

export type Data = {any: any}

return nil
